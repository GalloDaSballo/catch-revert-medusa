// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/Rebasor.sol";

contract CounterTest is Test {
    Rebasor public rebasor;
    FakeRebasableETH public STETH;

    function setUp() public {
        rebasor = new Rebasor();
        STETH = rebasor.STETH();

        // Always deposit
        STETH.depositAndMint(124);
    }

    function testDepositAndMint() public {
        // Check we have right balance
        assertTrue(STETH.balanceOf(address(this)) == 124);

        // And linear increment has linear minting
        STETH.depositAndMint(124);
        assertTrue(STETH.balanceOf(address(this)) == 248);
    }

    function testSkewRatioPositive() public {
        // We double the underlying
        STETH.addUnderlying(124);

        // Shares didn't change
        assertTrue(STETH.sharesOf(address(this)) == 124);

        // but we get double value
        assertTrue(STETH.balanceOf(address(this)) == 248);
    }

    function testSkewRatioNegative() public {
        // We remove the underlying
        STETH.removeUnderlying(123);

        // Shares didn't change
        assertTrue(STETH.sharesOf(address(this)) == 124);

        // we are left with 1 of value
        assertTrue(STETH.balanceOf(address(this)) == 1);
    }

    function testBasicDeposit() public {
        rebasor.deposit(100);

        assertTrue(rebasor.allShares() == 100);
        assertTrue(rebasor.sharesDeposited(address(this)) == 100);
        assertTrue(rebasor.stFFPScdp(address(this)) == 1e18);
        assertTrue(rebasor.stFFPSg() == 1e18);
    }

    function testBasicCollateral() public {
        rebasor.deposit(100);

        assertTrue(rebasor.collateralCDP(address(this)) == 100);
    }

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

    function testRebaseDown() public {
        rebasor.deposit(100);

        // Remove half
        vm.warp(block.timestamp + 86400);
        STETH.removeUnderlying(62);

        // Lost 50%
        assertEq(rebasor.collateralCDP(address(this)), 50);
    }
}
