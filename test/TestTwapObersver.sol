// SPDX-License Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/ExampleTwap.sol";
import "src/TwapObserver.sol";

contract ExampleTwapObserverTest is Test {
    ExampleTwap twapAcc;
    ExampleTwapObserver twapTester;

    function setUp() public {
        twapAcc = new ExampleTwap(0);
        twapTester = new ExampleTwapObserver(address(twapAcc));
    }

    function _log() internal {
        console2.log("");
        console2.log(block.timestamp);
        console2.log("twapAcc.getRealValue();", twapAcc.getRealValue());
        console2.log("twapAcc.getLatestAccumulator();", twapAcc.getLatestAccumulator());

        console2.log("twapAcc.observe();", twapTester.observe());
    }

    function testDebugObserver() public {
        uint256 ONE_HUNDRED = 100;
        uint256 ONE_WEEK = 1 weeks;

        vm.warp(10);
        twapAcc.setValue(ONE_HUNDRED);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 1);
        twapTester.update();
        _log();

        vm.warp(ONE_WEEK * 2);
        twapTester.update();
        _log();

        vm.warp(ONE_WEEK * 3);

        twapAcc.setValue(ONE_HUNDRED * 50);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 10);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 1 days);
        twapAcc.setValue(ONE_HUNDRED * 20);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 2 days);
        twapAcc.setValue(ONE_HUNDRED * 10);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 3 days);
        twapAcc.setValue(ONE_HUNDRED * 1);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 4 days);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 5 days);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 6 days);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 7 days);
        twapTester.update();
        _log();
        vm.warp(ONE_WEEK * 3 + 8 days);
        _log();
    }
}
