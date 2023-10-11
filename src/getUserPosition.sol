pragma solidity ^0.8.0;

import "openzeppelin-contracts-06/contracts/token/ERC20/IERC20.sol";

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function borrowBalanceStored(
        address account
    ) external view returns (uint256);
}

interface IComptroller {
    function getAssetsIn(
        address account
    ) external view returns (ICToken[] memory);
}

interface IratherNFT {
    function mint(
        address user,
        string memory tokenURI
    ) external returns (uint256);
}

contract UserPosition {
    IComptroller public comptroller;
    IratherNFT public nftContract; // NFT contract interface
    IERC20 public usdcToken; // Fake USDC interface

    uint256 public insuranceFee = 10; // Example fee. Adjust as necessary.

    mapping(address => uint256) public insuredAmount;

    constructor(address _comptroller, address _nftAddress, address _usdcToken) {
        comptroller = IComptroller(_comptroller);
        nftContract = IratherNFT(_nftAddress);
        usdcToken = IERC20(_usdcToken);
    }

    function buyInsurance() public {
        // Transfer USDC fee from user to this contract
        require(
            usdcToken.transferFrom(msg.sender, address(this), insuranceFee),
            "USDC transfer failed!"
        );

        // Mint NFT
        string memory metadata = _generateMetadata(msg.sender);
        nftContract.mint(msg.sender, metadata);

        // Logic to store the purchased insurance details can be added here
    }

    function _generateMetadata(
        address user
    ) internal pure returns (string memory) {
        // Logic to generate metadata for the NFT based on the user's position
        // This can be as simple or as complex as you need.
        // For example, you could fetch details of the user's position and format it into a JSON string.

        return
            string(
                abi.encodePacked(
                    'data:application/json,{"name":"Insurance for ',
                    user,
                    '","description":"NFT representing insurance policy."}'
                )
            );
    }

    function getUserPosition(
        address user
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        ICToken[] memory enteredCTokens = comptroller.getAssetsIn(user);

        address[] memory cTokenAddresses = new address[](enteredCTokens.length);
        uint256[] memory sizeOfLent = new uint256[](enteredCTokens.length);
        uint256[] memory sizeOfBorrow = new uint256[](enteredCTokens.length);
        uint256[] memory totalInsured = new uint256[](enteredCTokens.length);

        for (uint256 i = 0; i < enteredCTokens.length; i++) {
            uint256 cTokenBalance = enteredCTokens[i].balanceOf(user);
            uint256 exchangeRate = enteredCTokens[i].exchangeRateStored();

            cTokenAddresses[i] = address(enteredCTokens[i]);
            sizeOfLent[i] = (cTokenBalance * exchangeRate) / 1e18;
            sizeOfBorrow[i] = enteredCTokens[i].borrowBalanceStored(user);
            totalInsured[i] = insuredAmount[user];
        }

        return (cTokenAddresses, sizeOfLent, sizeOfBorrow, totalInsured);
    }
}
