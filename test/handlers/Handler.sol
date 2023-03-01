// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;

import {FakeRebasableETH, Rebasor} from "../../src/Rebasor.sol";

import {CommonBase} from "forge-std/Base.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console} from "forge-std/console.sol";

contract Handler is CommonBase, StdUtils {
    // CONSTANTS
    uint256 constant MINT_TEST_AMOUNT = 10 ether;
    uint256 constant TIME_JUMP_INTERVAL = 86400;

    // STORAGE
    FakeRebasableETH public STETH;
    Rebasor public rebasor;

    uint256 public ghost_depositSum;
    uint256 public ghost_rebaseUpSum;
    uint256 public ghost_rebaseDownSum;

    // ZERO CASE ACCOUNTING
    uint256 public ghost_zeroRebaseUp;
    uint256 public ghost_zeroRebaseDown;

    mapping(bytes32 => uint256) public calls;

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(Rebasor _rebasor, FakeRebasableETH _stETH) public {
        rebasor = _rebasor;
        STETH = _stETH;

        STETH.depositAndMint(MINT_TEST_AMOUNT);
    }

    function deposit(uint256 amount) public countCall("deposit") {
        amount = bound(amount, 0, STETH.balanceOf(address(this)));

        rebasor.deposit(amount);

        ghost_depositSum += amount;
    }

    function rebaseUp(uint256 amount) public countCall("rebaseUp") {
        amount = bound(amount, 0, STETH.balanceOf(address(this)));
        if (amount == 0) ghost_zeroRebaseUp++;

        STETH.addUnderlying(amount);

        if (rebasor.sharesDeposited(address(this)) > 0) {
            vm.warp(block.timestamp + TIME_JUMP_INTERVAL);
            rebasor.collateralCDP(address(this));
        }

        ghost_rebaseUpSum += amount;
    }

    function rebaseDown(uint256 amount) public countCall("rebaseDown") {
        amount = bound(amount, 0, STETH.balanceOf(address(this)));
        if (amount == 0) ghost_zeroRebaseDown++;

        STETH.removeUnderlying(amount);

        if (rebasor.sharesDeposited(address(this)) > 0) {
            vm.warp(block.timestamp + TIME_JUMP_INTERVAL);
            rebasor.collateralCDP(address(this));
        }

        ghost_rebaseDownSum += amount;
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("rebaseUp", calls["rebaseUp"]);
        console.log("rebaseDown", calls["rebaseDown"]);
        console.log("-------------------");

        console.log("Deposit Sum:", ghost_depositSum);
        console.log("Rebase Up Sum:", ghost_rebaseUpSum);
        console.log("Rebase Down Sum:", ghost_rebaseDownSum);
        console.log("-------------------");

        console.log("Zero Rebase Up:", ghost_zeroRebaseUp);
        console.log("Zero Rebase Down:", ghost_zeroRebaseDown);
    }
}
