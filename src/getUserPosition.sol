pragma solidity ^0.8.0;

import "openzeppelin-contracts-06/contracts/token/ERC20/IERC20.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "openzeppelin-contracts-06/contracts/utils/Strings.sol";
import "openzeppelin-contracts-06/contracts/access/AccessControl.sol";
import "./userPositionStorage.sol";

contract UserPosition is UserPositionStorage, AccessControl {
    constructor(address _comptroller, address _nftAddress, address _usdcToken) {
        comptroller = IComptroller(_comptroller);
        nftContract = IratherNFT(_nftAddress);
        usdcToken = IERC20(_usdcToken);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(INSURANCE_ROLE, ADMIN_ROLE);
    }

    function setPriceFeed(
        address underlyingToken,
        address feed
    ) external onlyRole(ADMIN_ROLE) {
        priceFeeds[underlyingToken] = AggregatorV3Interface(feed);
    }

    function getLatestPrice(address aggregator) public view returns (int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(aggregator);
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function buyInsurance() public {
        require(
            usdcToken.transferFrom(msg.sender, address(this), insuranceFee)
        );
        uint256 insuranceAmount = offerInsurance(msg.sender);
        totalInsuredAmountByUser[msg.sender] += insuranceAmount;
        string memory metadata = _generateMetadata(msg.sender);
        uint256 tokenId = nftContract.mint(msg.sender, metadata);
        tokenInsuredAmount[tokenId] = insuranceAmount;
        totalNFTsMinted += 1;
    }

    function getUserPosition(
        address user
    ) public view returns (PositionData memory) {
        ICToken[] memory enteredCTokens = comptroller.getAssetsIn(user);

        PositionData memory position;
        position.cTokenAddresses = new address[](enteredCTokens.length);
        position.sizeOfLentUSD = new uint256[](enteredCTokens.length);
        position.sizeOfBorrowUSD = new uint256[](enteredCTokens.length);
        position.totalInsuredUSD = new uint256[](enteredCTokens.length);

        for (uint256 i = 0; i < enteredCTokens.length; i++) {
            (
                position.cTokenAddresses[i],
                position.sizeOfLentUSD[i],
                position.sizeOfBorrowUSD[i],
                position.totalInsuredUSD[i]
            ) = getPositionDataForToken(user, enteredCTokens[i]);
        }

        return position;
    }

    function getPositionDataForToken(
        address user,
        ICToken cToken
    ) internal view returns (address, uint256, uint256, uint256) {
        address cTokenAddress = address(cToken);
        uint256 lentValueUSD = computeLentValueUSD(user, cToken);
        uint256 borrowValueUSD = computeBorrowValueUSD(user, cToken);
        uint256 totalInsuredValueUSD = 0; // Using underlying token here
        return (
            cTokenAddress,
            lentValueUSD,
            borrowValueUSD,
            totalInsuredValueUSD
        );
    }

    function claimInsurance(uint256 tokenId) public {
        require(getNetPositionInUSDC(msg.sender) < 0);
        uint256 insuredAmt = tokenInsuredAmount[tokenId];
        require(insuredAmt > 0);
        uint256 claimAmount = insuredAmt - insuranceClaimFee;
        require(usdcToken.transfer(msg.sender, claimAmount));
        nftContract.transferFrom(msg.sender, BURN_ADDRESS, tokenId);
        tokenInsuredAmount[tokenId] = 0;
    }

    function updatePosition(address user, uint256 tokenId) public {
        string memory metadata = _generateMetadata(user);
        nftContract.updateTokenURI(tokenId, metadata);
    }

    function deposit(address tokenAddress, uint256 amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount));
        depositedTokens[tokenAddress] += amount;
    }

    function withdraw(address tokenAddress, uint256 amount) public {
        require(depositedTokens[tokenAddress] >= amount);
        depositedTokens[tokenAddress] -= amount;
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount));
    }

    function offerInsurance(address user) public view returns (uint256) {
        int256 netPosition = getNetPositionInUSDC(user);
        require(netPosition > 0);
        uint256 insuranceCost = uint256(netPosition) / 100;
        return insuranceCost;
    }

    function getTotalInsured(address user) public view returns (uint256) {
        return totalInsuredAmountByUser[user];
    }

    function getNetPositionInUSDC(address user) public view returns (int256) {
        (
            uint error,
            uint accountLiquidityUint,
            uint shortFallUint
        ) = comptroller.getAccountLiquidity(user);
        int256 accountLiquidity = int256(accountLiquidityUint);
        int256 shortFall = int256(shortFallUint);
        if (shortFall > 0) {
            return -shortFall;
        }
        return accountLiquidity;
    }

    function computeLentValueUSD(
        address user,
        ICToken cToken
    ) internal view returns (uint256) {
        return
            (((cToken.balanceOf(user) * cToken.exchangeRateStored()) / 1e18) *
                uint256(
                    getLatestPrice(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419)
                )) / 1e18;
    }

    function computeBorrowValueUSD(
        address user,
        ICToken cToken
    ) internal view returns (uint256) {
        return
            (cToken.borrowBalanceStored(user) *
                uint256(
                    getLatestPrice(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419)
                )) / 1e18;
    }

    function _generateMetadata(
        address user
    ) internal view returns (string memory) {
        string memory userAddress = toAsciiString(user);
        int256 netPosition = getNetPositionInUSDC(user);
        string memory positionHealth = netPosition > 0 ? "Healthy" : "At Risk";
        string memory attributes = constructAttributes(
            user,
            netPosition,
            positionHealth
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json,{",
                    '"name":"Insurance for ',
                    userAddress,
                    '",',
                    '"description":"NFT representing insurance policy for ',
                    userAddress,
                    '",',
                    attributes,
                    "}"
                )
            );
    }

    function toAsciiString(
        address _addr
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function constructAttributes(
        address userAddress,
        int256 netPosition,
        string memory positionHealth
    ) internal view returns (string memory) {
        string memory insured = uintToString(getTotalInsured(userAddress));
        string memory user = toAsciiString(userAddress);
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    '{ "trait_type": "Insured", "value": "',
                    insured,
                    '" },',
                    '{ "trait_type": "User Address", "value": "',
                    user,
                    '" },',
                    '{ "trait_type": "Net Position", "value": "',
                    uintToString(uint256(netPosition)),
                    '" },',
                    '{ "trait_type": "Position Health", "value": "',
                    positionHealth,
                    '" }',
                    "]"
                )
            );
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }

    function grantAdminRole(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
    }

    function revokeAdminRole(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
    }
}
