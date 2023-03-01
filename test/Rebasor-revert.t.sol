// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/Rebasor.sol";

contract RevertTests is Test {
    Rebasor public rebasor;
    FakeRebasableETH public STETH;

    function setUp() public {
        rebasor = new Rebasor();
        STETH = rebasor.STETH();

        // Always deposit
        STETH.depositAndMint(124);
    }

    // Baseline up
    function testRebaseUp() public {
        rebasor.deposit(100);
        assertEq(rebasor.allStakes(), 100);
        assertEq(rebasor.stakes(address(this)), 100);

        // Doubled
        vm.warp(block.timestamp + 86400);
        STETH.addUnderlying(124);

        // 150 as we start with 100, we grow by 100, we take 50% fee
        assertEq(rebasor.collateralCDP(address(this)), 150);
    }

    /**
        the test amount is too small without scaling so some precision is lost in solidity
     */
    function testRebaseUpDistributiveProperty() public {
        // Taking 50% twice is NOT the same as taking 50% once with twice the amount 
        // due to the nonlinearity of share convertion:
        //
        // - 50% once with [index increase 2X] AND [starting deposited share S]:
        //       fee = 50% * 2X * S
        //       feeShare = fee / (1+2X)
        // - 50% twice with [index increase X] AND [starting deposited share S]:
        //       fee1 = 50% * X * S
        //       fee1Share = fee1 / (1+X) = 1/2 * (50% * 2X * S) / (1+X) = 1/2 * fee  / (1+X) > 1/2 * feeShare
        //       fee2 = 50% * X * (S - fee1Share)
        //
        // The more parts (smaller) there are, the more fee will be taken.
        // We prefer 100 successive small 1% increases over a single big 100% increase 	
        //
        rebasor.deposit(100);
        uint256 _startAllShares = rebasor.allShares();
        assertEq(_startAllShares, 100);
        assertEq(rebasor.stakes(address(this)), rebasor.allStakes());

        // Quarter
        vm.warp(block.timestamp + 86400);
        assertEq(rebasor.getValueAtCurrentIndex(), 100);
        STETH.addUnderlying(62);// getPooledEthByShares() increase from 1 to 1.5, delta is 0.5
        (uint256 _deltaFeeSplitShare, uint256 _deltaPerUnit, ) = rebasor.calcFeeUponStakingReward(STETH.getPooledEthByShares(1e18), rebasor.stFFPScdp(address(this)));
        assertEq(_deltaPerUnit, 166666666666666666);// 0.5 * 100 * 50% = 25 / 1.5 = 16.66666666

        // Quarter
        assertEq(rebasor.collateralCDP(address(this)), 124);// (100 - 16.66666) * 1.5 = 83 * 1.5 = 124
        assertEq(rebasor.stakes(address(this)), rebasor.allStakes());
        assertEq(rebasor.allShares(), ((_startAllShares * 1e18) - _deltaFeeSplitShare) / 1e18);

        // Another Quarter
        vm.warp(block.timestamp + 86400);
        STETH.addUnderlying(62);// getPooledEthByShares() increase from 1.5 to 2, delta is 0.5
        (uint256 _deltaFeeSplitShare2, uint256 _deltaPerUnit2, ) = rebasor.calcFeeUponStakingReward(STETH.getPooledEthByShares(1e18), rebasor.stFFPScdp(address(this)));
        assertEq(_deltaPerUnit2, 103750000000000000);// 0.5 * 83 * 50% = 20.75 / 2 = 10.375

        // Half
        assertEq(rebasor.collateralCDP(address(this)), 144);// (83 - 10.375) * 2 = 72 * 2 = 144
        assertEq(rebasor.stakes(address(this)), rebasor.allStakes());
        assertEq(rebasor.allShares(), ((_startAllShares * 1e18) - _deltaFeeSplitShare - _deltaFeeSplitShare2) / 1e18);
    }

    /**
        test with scaled amount for more precision
     */
    function testRebaseUpDistributivePropertyScaled() public {
	
        Rebasor scaledRebasor = new Rebasor();
        FakeRebasableETH scaledSTETH = scaledRebasor.STETH();
        scaledSTETH.depositAndMint(124e18);
		
        scaledRebasor.deposit(100e18);
        uint256 _startAllShares = scaledRebasor.allShares();
        assertEq(_startAllShares, 100e18);
        assertEq(scaledRebasor.stakes(address(this)), scaledRebasor.allStakes());

        // Quarter
        vm.warp(block.timestamp + 86400);
        assertEq(scaledRebasor.getValueAtCurrentIndex(), 100e18);
        scaledSTETH.addUnderlying(62e18);// getPooledEthByShares() increase from 1 to 1.5, delta is 0.5

        // Quarter
        assertEq(scaledRebasor.collateralCDP(address(this)), 125000000000000000100);
        assertEq(scaledRebasor.stakes(address(this)), scaledRebasor.allStakes());
        assertEq(scaledRebasor.allShares(), 83333333333333333350);

        // Another Quarter
        vm.warp(block.timestamp + 86400);
        scaledSTETH.addUnderlying(62e18);// getPooledEthByShares() increase from 1.5 to 2, delta is 0.5

        // Half
        assertEq(scaledRebasor.collateralCDP(address(this)), 145833333333333333386);
        assertEq(scaledRebasor.stakes(address(this)), scaledRebasor.allStakes());
        assertEq(scaledRebasor.allShares(), 72916666666666666631);
    }

    // Baseline Down
    function testRebaseDown() public {
        rebasor.deposit(100);

        // Remove half
        vm.warp(block.timestamp + 86400);
        STETH.removeUnderlying(62);

        // Lost 50%
        assertEq(rebasor.collateralCDP(address(this)), 50);
    }

    function testRebaseDownDistributiveProperty() public {
        rebasor.deposit(100);

        // Remove a quarter
        vm.warp(block.timestamp + 86400);
        STETH.removeUnderlying(31);

        // Lost 25%
        assertEq(rebasor.collateralCDP(address(this)), 75);

        // Remove another quarter
        vm.warp(block.timestamp + 86400);
        STETH.removeUnderlying(31);

        // Lost 50%
        assertEq(rebasor.collateralCDP(address(this)), 50);
    }

    /**
        Reverts because of some weird issue
     */
    // function testDepositAndMintFuzz(uint64 initialAmount, uint64 secondAmount) public {
    //     // TODO
    //     vm.assume(initialAmount > 0);
    //     vm.assume(secondAmount > 0);
    //     vm.assume((initialAmount + secondAmount) > 0);

    //     // Always deposit
    //     STETH.depositAndMint(initialAmount);

    //     // Check we have right balance
    //     assertEq(STETH.balanceOf(address(this)), initialAmount);

    //     // And linear increment has linear minting
    //     assertEq(STETH.getSharesByPooledEth(secondAmount), secondAmount);

        
    //     STETH.depositAndMint(secondAmount);
    //     uint256 expectedTotal = initialAmount + secondAmount;
    //     log_uint(initialAmount);
    //     log_uint(secondAmount);
    //     log_uint(expectedTotal);
    //     assertEq(STETH.balanceOf(address(this)), expectedTotal);
    // }

}
