pragma solidity ^0.8.13;

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
    IERC20 public usdc; // Add USDC token interface
    IratherNFT public nftContract; // Interface to interact with the NFT contract
    uint256 public insuranceFee = 10 * 1e6; // Set a fee of 10 USDC (adjust as needed)

    mapping(address => uint256) public insuredAmount;

    constructor(address _comptroller, address _usdc, address _nftContract) {
        comptroller = IComptroller(_comptroller);
        usdc = IERC20(_usdc);
        nftContract = IratherNFT(_nftContract);
    }

    function purchaseInsurance(string memory tokenURI) external {
        require(
            usdc.transferFrom(msg.sender, address(this), insuranceFee),
            "USDC transfer failed"
        );
        nftContract.mint(msg.sender, tokenURI);
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
