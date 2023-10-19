pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/getUserPosition.sol";
import "../src/ratherNFT.sol";
import "../src/mockUSDC.sol";
import "openzeppelin-contracts-06/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICompound.sol";
import "../src/userPositionStorage.sol";

// Mock contracts for interfaces like IComptroller, IratherNFT, IERC20, etc.

contract UserPositionTest is Test {
    UserPosition userPosition;
    MockUSDC mockUsdc;
    ratherNFT _ratherNFT;
    UserPositionStorage userPositionStorage;

    uint supplyRate;
    uint exchangeRate;
    uint estimateBalance;
    uint balanceOfUnderlying;
    uint borrowedBalance;
    uint price;
    uint rerror;
    uint liquidity;
    uint shortfall;
    uint colFactor;
    uint supplied;
    uint liqbalance;

    IWETH WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CErc20 C_WETH = CErc20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 CDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    Comptroller comptroller =
        Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    PriceFeed priceFeed = PriceFeed(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1); //UniswapAnchoredView

    address cToken = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;

    uint256 public constant AMOUNT = 1e18;
    uint256 MAX_INT = 2 ** 256 - 1;

    // Comptroller comptroller =
    //     Comptroller(0x3cBe63aAcF6A064D32072a630A3eab7545C54d78);

    function setUp() public {
        vm.createSelectFork(vm.envString("mainnet"), 18373227);
        vm.prank(0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3);

        // Convert 1 Ether to WETH
        bool success = WETH.transfer(address(this), 1e18);
        require(success, "WETH transfer failed");

        // Approve C_WETH to spend WETH
        WETH.approve(address(C_WETH), 1e18);

        mockUsdc = new MockUSDC();
        _ratherNFT = new ratherNFT();
        userPositionStorage = new UserPositionStorage();

        // Initialize your other mock contracts like IComptroller, IratherNFT, etc.

        userPosition = new UserPosition(
            address(comptroller),
            address(_ratherNFT),
            address(mockUsdc)
        );
    }

    function testGetUserPosition() public {
        // 1. Supply some WETH to get C_WETH tokens.
        // vm.startPrank(0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3);

        C_WETH.mint{value: 1e18}();

        console.log("---- Get User Position Test----");

        borrow(address(CDAI), 18);
        CDAI.borrowBalanceCurrent(address(this));
        borrowedBalance = CDAI.borrowBalanceCurrent(address(this));
        emit log_named_uint("borrowedBalance:", borrowedBalance / 1e18);

        emit log_named_uint(
            "Borrowed DAI:",
            DAI.balanceOf(address(this)) / 1e18
        );

        PositionData memory position = userPosition.getUserPosition(
            address(this)
        );

        int256 getPosition = userPosition.getNetPositionInUSDC(address(this));

        emit log_named_int("borrowedBalance:", getPosition);

        for (uint256 i = 0; i < position.cTokenAddresses.length; i++) {
            emit log_named_address(
                "cTokenAddress:",
                position.cTokenAddresses[i]
            );
            emit log_named_uint("sizeOfLentUSD:", position.sizeOfLentUSD[i]);
            emit log_named_uint(
                "sizeOfBorrowUSD:",
                position.sizeOfBorrowUSD[i]
            );
            emit log_named_uint(
                "totalInsuredUSD:",
                position.totalInsuredUSD[i]
            );
        }

        // 4. Validate the returned data.

        // Assuming you've only entered the C_WETH and CDAI markets:
        assertEq(
            position.cTokenAddresses.length,
            2,
            "Unexpected number of cTokens"
        );

        // // Check for C_WETH and CDAI in the position's cToken addresses.
        bool hasCWETH = false;
        bool hasCDAI = false;
        for (uint i = 0; i < position.cTokenAddresses.length; i++) {
            if (position.cTokenAddresses[i] == address(C_WETH)) {
                hasCWETH = true;
            } else if (position.cTokenAddresses[i] == address(CDAI)) {
                hasCDAI = true;
            }
        }
        assertTrue(hasCWETH, "Missing C_WETH in user position");
        assertTrue(hasCDAI, "Missing CDAI in user position");

        console.log("---- Test Buy Insurance----");

        // Assuming you've already minted some MockUSDC for your contract.
        uint256 insuranceAmount = 10e6; // 1000 MockUSDC
        mockUsdc.transfer(address(this), insuranceAmount); // Send MockUSDC to this contract

        mockUsdc.approve(address(userPosition), insuranceAmount);

        userPosition.buyInsurance();

        uint256 insurancePurchased = userPosition.getTotalInsured(
            address(this)
        );

        emit log_named_uint("insurancePurchased:", insurancePurchased);

        uint256 idNFT = _ratherNFT.balanceOf(address(this));

        console.log("---- NFT test INSURANCE----");

        emit log_named_uint("idNFT", idNFT);

        console.log("---- test LIQUIDATION----");

        address borrower = address(this);
        uint borrowedAmount = CDAI.borrowBalanceCurrent(borrower);

        uint repayAmount = borrowedAmount / 2;

        DAI.approve(address(CDAI), repayAmount);

        // Liquidator calls the liquidateBorrow function
        // CDAI.liquidateBorrow(borrower, repayAmount, address(C_WETH));

        // uint remainingDebt = CDAI.borrowBalanceCurrent(borrower);

        // emit log_named_uint("remainingDebt", remainingDebt);

        // Note: You'll need to determine the indices [0] and [1] based on the order in which cTokens are returned.
    }

    function testSupplyRedeem() public {
        console.log("----Before testing supply, all status:----");

        exchangeRate = C_WETH.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", exchangeRate);

        supplyRate = C_WETH.supplyRatePerBlock();
        emit log_named_uint("supplyRate:", supplyRate);

        uint256 contractBalanceWETH = WETH.balanceOf(address(this));
        console.log("Contract WETH Balance:", contractBalanceWETH);

        // estimateBalance = estimateBalanceOfUnderlying();
        // emit log_named_uint("estimateBalance:", estimateBalance);

        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        uint256 contractBalanceCWETH = C_WETH.balanceOf(address(this));
        console.log("Contract C_WETH Balance:", contractBalanceCWETH);

        uint256 etherBalance = address(this).balance;
        console.log("Contract Ether Balance:", etherBalance);

        C_WETH.mint{value: 1e18}();

        console.log("----After supplying, all status:----");
        emit log_named_uint(
            "Supplied 1 eth to get C_WETH:",
            C_WETH.balanceOf(address(this))
        );

        exchangeRate = C_WETH.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", supplyRate);

        supplyRate = C_WETH.supplyRatePerBlock();
        emit log_named_uint("supplyRate:", supplyRate);

        estimateBalance = estimateBalanceOfUnderlying();
        emit log_named_uint("estimateBalance:", estimateBalance);

        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        console.log("----Test supply interest ----");
        vm.roll(18373227); // Get interest per block.
        exchangeRate = C_WETH.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", supplyRate);
        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        console.log("----Test Redeem----");
        uint cTokenAmount = C_WETH.balanceOf(address(this));
        C_WETH.redeem(balanceOfUnderlying);

        emit log_named_uint("Redeemed ETC:", WETH.balanceOf(address(this)));
        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);
    }

    // Mint WETH into C_WETH
    //     uint mintResult = C_WETH.mint(contractBalanceWETH);
    //     console.log("Mint result:", mintResult);
    // }

    function estimateBalanceOfUnderlying() public returns (uint) {
        uint cTokenBal = C_WETH.balanceOf(address(this));
        uint exchangeRate = C_WETH.exchangeRateCurrent();
        uint decimals = 8; // C_WETH = 8 decimals
        uint cTokenDecimals = 8;

        return
            (cTokenBal * exchangeRate) / 10 ** (18 + decimals - cTokenDecimals);
    }

    function testBorrow() public {
        console.log("----Before borrow testing supply, all status:----");
        exchangeRate = C_WETH.exchangeRateCurrent();
        emit log_named_uint("exchangeRate:", supplyRate);

        supplyRate = C_WETH.supplyRatePerBlock();
        emit log_named_uint("supplyRate:", supplyRate);

        estimateBalance = estimateBalanceOfUnderlying();
        emit log_named_uint("estimateBalance:", estimateBalance);

        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        C_WETH.mint{value: 1e18}();

        console.log("----Test Borrow----");

        borrow(address(CDAI), 18);
        CDAI.borrowBalanceCurrent(address(this));
        borrowedBalance = CDAI.borrowBalanceCurrent(address(this));
        emit log_named_uint("borrowedBalance:", borrowedBalance / 1e18);

        emit log_named_uint(
            "Borrowed DAI:",
            DAI.balanceOf(address(this)) / 1e18
        );

        comptroller.getAccountLiquidity(address(this));

        console.log("----Test Repay----");
        repay(address(DAI), address(CDAI), MAX_INT);
        emit log_named_uint("Borrowed DAI:", DAI.balanceOf(address(this)));

        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("balanceOfUnderlying:", balanceOfUnderlying);

        console.log("----Test Redeem----");
        uint cTokenAmount = C_WETH.balanceOf(address(this));
        C_WETH.redeem(balanceOfUnderlying);
        emit log_named_uint("Redeemed ETC:", WETH.balanceOf(address(this))); //0.99999999 ETC
        balanceOfUnderlying = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_uint("supplied:", balanceOfUnderlying);
    }

    function borrow(address _cTokenToBorrow, uint _decimals) public {
        // enter market
        // enter the supply market so you can borrow another type of asset
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cToken);
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        // check liquidity
        (uint error, uint liquidity, uint shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(error == 0, "error");
        require(shortfall == 0, "shortfall > 0");
        require(liquidity > 0, "liquidity = 0");

        // calculate max borrow
        price = priceFeed.getUnderlyingPrice(_cTokenToBorrow);

        // liquidity - USD scaled up by 1e18
        // price - USD scaled up by 1e18
        // decimals - decimals of token to borrow
        uint maxBorrow = (liquidity * (10 ** _decimals)) / price;
        emit log_named_uint("maxBorrow", maxBorrow);

        require(maxBorrow > 0, "max borrow = 0");

        // borrow 50% of max borrow
        uint amount = (maxBorrow * 50) / 100;
        // emit log_named_uint("amount:", amount);
        //CErc20(_cTokenToBorrow).borrow(amount) ;
        require(CErc20(_cTokenToBorrow).borrow(amount) == 0, "borrow failed");
    }

    function testliquidate() public {
        //getCollateralFactor

        console.log("----Test Supply: 1 ETH----");
        C_WETH.mint{value: 1e18}(); // supply 1 ETC.
        emit log_named_decimal_uint(
            "C_WETH balance of borrower:",
            C_WETH.balanceOf(address(this)),
            8
        );
        (, colFactor, ) = comptroller.markets(address(C_WETH));
        emit log_named_decimal_uint("colFactor: %", colFactor, 16);

        supplied = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_decimal_uint("supplied: ", supplied / 100, 6);

        price = priceFeed.getUnderlyingPrice(address(CDAI));
        emit log_named_decimal_uint("CDAI price: ", price, 18);

        console.log("----Test Borrow----");
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cToken);
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        (uint error, uint liquidity, uint shortfall) = comptroller
            .getAccountLiquidity(address(this));

        emit log_named_decimal_uint("liquidity:", liquidity / 10000, 14);
        emit log_named_decimal_uint("shortfall:", shortfall / 10000, 14);

        // calculate max borrow
        price = priceFeed.getUnderlyingPrice(address(CDAI));
        emit log_named_decimal_uint("CDAI Price:", price, 18);

        // liquidity - USD scaled up by 1e18
        // price - USD scaled up by 1e18
        // decimals - decimals of token to borrow
        uint maxBorrow = (liquidity * (10 ** 18)) / price;
        emit log_named_decimal_uint("maxBorrow", maxBorrow, 18);

        CDAI.borrow(1287259182932781823172);
        emit log_named_decimal_uint(
            "Borrowed DAI:",
            DAI.balanceOf(address(this)),
            18
        );

        CDAI.borrowBalanceCurrent(address(this));
        borrowedBalance = CDAI.borrowBalanceCurrent(address(this));
        emit log_named_decimal_uint("borrowedBalance:", borrowedBalance, 18);
        (rerror, liquidity, shortfall) = comptroller.getAccountLiquidity(
            address(this)
        );
        emit log_named_decimal_uint(
            "Borrowed, liquidity:",
            liquidity / 10000,
            14
        );
        emit log_named_decimal_uint(
            "Borrowed, shortfall:",
            shortfall / 10000,
            14
        );

        vm.roll(18378114);
        console.log("----After some blocks---");
        liqbalance = DAI.balanceOf(0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3);
        emit log_named_uint("Liquidator DAI balance:", liqbalance / 10 ** 18);

        // cheats.mockCall(
        //     address(comptroller),
        //     abi.encodeWithSelector(Comptroller.getAccountLiquidity.selector),
        //     abi.encode(0, 0, 1000000000000000000)
        // );
        (error, liquidity, shortfall) = comptroller.getAccountLiquidity(
            address(this)
        );

        emit log_named_decimal_uint("Afterliquidity:", liquidity / 10000, 14);
        emit log_named_decimal_uint("Aftershortfall:", shortfall / 10000, 14);

        uint closeFactor = comptroller.closeFactorMantissa();
        emit log_named_uint("closeFactor:", closeFactor / 10 ** 16);
        uint repayAmount = (borrowedBalance * closeFactor) / 10 ** 18;
        emit log_named_uint("repayAmount:", repayAmount / 10 ** 18);

        (uint e, uint cTokenCollateralAmount) = comptroller
            .liquidateCalculateSeizeTokens(
                address(CDAI),
                address(C_WETH),
                repayAmount
            );
        emit log_named_uint(
            "amountToBeLiquidated:",
            cTokenCollateralAmount / 10 ** 6 / 100
        );

        console.log("----Test liquidation----");
        // repay(address(DAI),address(CDAI),MAX_INT);
        emit log_named_uint(
            "Borrowed DAI:",
            DAI.balanceOf(address(this)) / 1e18
        );
        vm.startPrank(0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3);
        DAI.approve(address(CDAI), repayAmount);

        uint256 allowedAmount = DAI.allowance(address(this), address(CDAI));
        emit log_named_uint("allowance: ", allowedAmount);

        // //Liquidate here, the sender liquidates the borrowers collateral.
        // //The collateral seized is transferred to the liquidator.
        //CDAI.liquidateBorrow(address(this), repayAmount, address(C_WETH));

        supplied = C_WETH.balanceOfUnderlying(address(this));
        emit log_named_decimal_uint("supplied: ", supplied / 100, 6);

        borrowedBalance = CDAI.borrowBalanceCurrent(address(this));
        emit log_named_uint("borrowedBalance:", borrowedBalance / 1e18);

        uint incentive = comptroller.liquidationIncentiveMantissa();
        emit log_named_decimal_uint("incentive:", incentive / 100, 16); //1.08%

        uint liquidated = C_WETH.balanceOfUnderlying(
            address(0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3)
        );
        emit log_named_decimal_uint("liquidated: ", liquidated / 10000, 4); //0.3411

        emit log_named_decimal_uint(
            "C_WETH balance of liquidator:",
            C_WETH.balanceOf(0xcd6Eb888e76450eF584E8B51bB73c76ffBa21FF2),
            8
        );
    }

    function repay(
        address _tokenBorrowed,
        address _cTokenBorrowed,
        uint _amount
    ) public {
        IERC20(_tokenBorrowed).approve(_cTokenBorrowed, _amount);
        // _amount = 2 ** 256 - 1 means repay all
        require(
            CErc20(_cTokenBorrowed).repayBorrow(_amount) == 0,
            "repay failed"
        );
    }
}
