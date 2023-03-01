// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";

import {Handler} from "./handlers/Handler.sol";
import {FakeRebasableETH, Rebasor} from "../src/Rebasor.sol";

contract RebasorInvariants is Test {
    Rebasor public rebasor;
    FakeRebasableETH public STETH;
    Handler public handler;

    function setUp() public {
        rebasor = new Rebasor();
        STETH = rebasor.STETH();
        handler = new Handler(rebasor, STETH);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.rebaseUp.selector;
        selectors[2] = Handler.rebaseDown.selector;
        // TODO: another handler selector performing withdrawals

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    function invariant_stakesGlobalConservation() public {
        assertEq(rebasor.stakes(address(handler)), rebasor.allStakes());
    }

    function invariant_sharesGlobalConservation() public {
        assertEq(rebasor.sharesDeposited(address(handler)), rebasor.allShares());
    }

    function invariant_callSummary() public view {
        handler.callSummary();
    }
}
