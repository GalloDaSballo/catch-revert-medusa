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
        Reverts either because of my misunderstanding or because of a flaw in the math
     */
    function testRebaseUpDistributiveProperty() public {
        // Taking 50% twice is the same as taking 50% once on twice the amount
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
}
