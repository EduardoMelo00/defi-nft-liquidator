pragma solidity ^0.8.0;

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

contract UserPosition {
    IComptroller public comptroller;

    mapping(address => uint256) public insuredAmount;

    constructor(address _comptroller) {
        comptroller = IComptroller(_comptroller);
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
