pragma solidity ^0.8.0;

import "openzeppelin-contracts-06/contracts/token/ERC20/IERC20.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IComptroller {
    function getAssetsIn(
        address account
    ) external view returns (ICToken[] memory);

    function getAccountLiquidity(
        address account
    ) external view returns (uint, uint, uint);
}

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function borrowBalanceStored(
        address account
    ) external view returns (uint256);
}

interface IratherNFT {
    function mint(
        address user,
        string memory tokenData
    ) external returns (uint256);

    function updateTokenURI(uint256 tokenId, string memory tokenData) external;

    function tokenByIndex(uint256 index) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

struct PositionData {
    address[] cTokenAddresses;
    uint256[] sizeOfLentUSD;
    uint256[] sizeOfBorrowUSD;
    uint256[] totalInsuredUSD;
}

contract UserPositionStorage {
    IComptroller public comptroller;
    IratherNFT public nftContract;
    IERC20 public usdcToken;
    uint256 public lastUpkeepTime;
    uint256 public insuranceFee = 1;
    uint256 public totalNFTsMinted = 0;
    address immutable BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    mapping(address => AggregatorV3Interface) public priceFeeds;
    uint256 public insuranceClaimFee = 1e6;
    mapping(uint256 => uint256) public tokenInsuredAmount;
    mapping(address => uint256) public totalInsuredAmountByUser;
    mapping(address => uint256) public depositedTokens;
    address public userPositionContract;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant INSURANCE_ROLE = keccak256("INSURANCE_ROLE");

    function setUserPositionAddress(address _userPositionContract) external {
        require(userPositionContract == address(0));
        userPositionContract = _userPositionContract;
    }
}
