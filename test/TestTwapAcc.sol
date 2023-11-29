// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "src/ExampleTwap.sol";

contract ExampleTwapTest is Test {
    ExampleTwap twapAcc;

    function setUp() public {
        twapAcc = new ExampleTwap(0);
    }

    function testBasicTwap() public {
        uint256 entropy = 67842918170911949682054359726922204181906323355453850;
        vm.warp(10);
        twapAcc.setValue(100);

        while (entropy > 0) {
            uint256 randomSeed = entropy % 10;
            entropy /= 10; // Cut the value

            if (twapAcc.valueToTrack() == 0) {
                twapAcc.setValue(randomSeed);
                continue;
            }

            if (randomSeed > 5) {
                twapAcc.setValue(twapAcc.valueToTrack() * (randomSeed - 5));
            } else {
                twapAcc.setValue(twapAcc.valueToTrack() * (5 - randomSeed) / 10);
            }
            vm.warp(10);
            console2.log("getRealValue", twapAcc.getRealValue());
            console2.log("getLatestAccumulator", twapAcc.getLatestAccumulator());
        }
    }

    function testIsOverflowAValidConcern() public {
        // 10 Billion USD
        // 10_000 years
        uint256 TEN_THOUSAND_YEARS = 10_000 * 365.25 days;
        uint256 TEN_BILLION_USD = 10e27; // 10 billion in 18 decimals

        twapAcc.setValue(TEN_BILLION_USD);

        vm.warp(TEN_THOUSAND_YEARS);

        console2.log("twapAcc.getRealValue();", twapAcc.getRealValue());
        console2.log("twapAcc.getLatestAccumulator()", twapAcc.getLatestAccumulator());
    }

    function _log() internal {
        console2.log("twapAcc.getRealValue();", twapAcc.getRealValue());
        console2.log("twapAcc.getLatestAccumulator();", twapAcc.getLatestAccumulator());
    }

    function testBasicDebug() public {
        uint256 ONE_MILLION = 1e6;
        uint256 ONE_YEAR = 1 * 365.25 days;

        vm.warp(0);

        twapAcc.setValue(ONE_MILLION);
        vm.warp(ONE_YEAR);
        console2.log("after one year");
        _log();

        twapAcc.setValue(ONE_MILLION * 2);
        vm.warp(ONE_YEAR * 2);
        console2.log("after one year");
        _log();

        vm.warp(ONE_YEAR * 3);
        console2.log("after one year");
        _log();
    }
}
