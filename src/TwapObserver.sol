// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

import {ExampleTwap} from "./ExampleTwap.sol";
import "forge-std/console2.sol";

contract ExampleTwapObserver {
    // last PriceCum
    // last T0

    uint256 priceCum0;
    uint256 t0;
    uint256 avgValue;

    uint256 constant PERIOD = 7 days;

    ExampleTwap immutable REFERENCE_TWAP;

    constructor(address twap) {
        REFERENCE_TWAP = ExampleTwap(twap);

        priceCum0 = ExampleTwap(twap).getLatestAccumulator();
        t0 = block.timestamp;
        avgValue = ExampleTwap(twap).getRealValue();
    }

    // Look at last
    // Linear interpolate (or prob TWAP already does that for you)

    function observe() external returns (uint256) {
        return avgValue;
    }

    function update() external returns (uint256) {
        if (block.timestamp >= t0 + PERIOD) {
            // Compute based on delta
            avgValue = (REFERENCE_TWAP.getLatestAccumulator() - priceCum0) / (block.timestamp - t0);

            // Then we update
            priceCum0 = REFERENCE_TWAP.getLatestAccumulator();
            t0 = block.timestamp;
        }
    }
}
