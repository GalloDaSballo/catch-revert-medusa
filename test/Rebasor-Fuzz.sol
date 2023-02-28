// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "forge-std/Test.sol";
import "../src/Rebasor.sol";

contract RebasorFuzz is Test {
    Rebasor public rebasor;
    FakeRebasableETH public STETH;

    function setUp() public {
        rebasor = new Rebasor();
        STETH = rebasor.STETH();

    }

    // function testDepositRebaseAttackMintFuzz(uint128 initialAmount, uint128 secondAmount) public {
    //     // This test fails because of the rebase attack

    //     vm.assume(initialAmount > 0);
    //     vm.assume(secondAmount > 0);
    //     vm.assume((initialAmount + secondAmount) > 0);
        
    //     // Else they overflow
    //     uint256 sum = uint128(initialAmount) + secondAmount;
    //     log_uint(sum);


    //     // Always deposit
    //     STETH.depositAndMint(initialAmount);

    //     // Check we have right balance
    //     assertEq(STETH.balanceOf(address(this)), initialAmount, "First Deposit");

    //     // And linear increment has linear minting
    //     assertEq(STETH.getSharesByPooledEth(secondAmount), secondAmount, "B4 Second Deposit");

        
    //     STETH.depositAndMint(secondAmount);
    //     assertEq(STETH.balanceOf(address(this)), sum, "Second Deposit");
    // }

    function testDepositNormalFuzz(uint64 initialAmount, uint64 secondAmount) public {        
        vm.assume(initialAmount > 0);
        vm.assume(secondAmount > 0);
        
        // Else they overflow
        uint256 sum = uint256(initialAmount) + uint256(secondAmount);
        log_uint(sum);


        // Always deposit
        STETH.depositAndMint(initialAmount);

        // Check we have right balance
        assertEq(STETH.balanceOf(address(this)), initialAmount, "First Deposit");

        // And linear increment has linear minting
        assertEq(STETH.getSharesByPooledEth(secondAmount), secondAmount, "B4 Second Deposit");

        
        STETH.depositAndMint(secondAmount);
        assertEq(STETH.sharesOf(address(this)), sum, "Shares Sum");
        assertEq(STETH.balanceOf(address(this)), sum, "Balance Second Deposit");


    }
}
