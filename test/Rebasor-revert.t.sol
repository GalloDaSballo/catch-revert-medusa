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
    }

    function testRebaseUp() public {
        // Always deposit
        STETH.depositAndMint(124);

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
        Reverts either because of my misunderstanding or because of a flaw in the math
     */
    function testRebaseUpDistributiveProperty() public {
        // Taking 50% twice is the same as taking 50% once on twice the amount

        // Always deposit
        STETH.depositAndMint(124);

        rebasor.deposit(100);
        assertEq(rebasor.allStakes(), 100);
        assertEq(rebasor.stakes(address(this)), 100);

        // Quarter
        vm.warp(block.timestamp + 86400);
        STETH.addUnderlying(62);

        // Quarter
        assertEq(rebasor.collateralCDP(address(this)), 125);

        // Another Quarter
        vm.warp(block.timestamp + 86400);
        STETH.addUnderlying(62);

        // Half
        assertEq(rebasor.collateralCDP(address(this)), 150);
    }

    /**
        Reverts because of some weird issue
     */
    function testDepositAndMintFuzz(uint64 initialAmount, uint64 secondAmount) public {
        // TODO
        vm.assume(initialAmount > 0);
        vm.assume(secondAmount > 0);
        vm.assume((initialAmount + secondAmount) > 0);

        // Always deposit
        STETH.depositAndMint(initialAmount);

        // Check we have right balance
        assertEq(STETH.balanceOf(address(this)), initialAmount);

        // And linear increment has linear minting
        assertEq(STETH.getSharesByPooledEth(secondAmount), secondAmount);

        
        STETH.depositAndMint(secondAmount);
        uint256 expectedTotal = initialAmount + secondAmount;
        log_uint(initialAmount);
        log_uint(secondAmount);
        log_uint(expectedTotal);
        assertEq(STETH.balanceOf(address(this)), expectedTotal);
    }

}
