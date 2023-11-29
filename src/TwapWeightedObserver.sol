// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

import {ExampleTwap} from "./ExampleTwap.sol";
import "forge-std/console2.sol";

contract TwapWeightedObserver {
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
        // Here, we need to apply the new accumulator to skew the price in some way
        // The weight of the skew should be proportional to the time passed

        if(block.timestamp - t0 == 0) {
            return avgValue;
        }

        // A reference period is 7 days
        // For each second passed after update
        // Let's virtally sync TWAP
        // With a weight, that is higher, the more time has passed
        uint256 virtualAvgValue = (REFERENCE_TWAP.getLatestAccumulator() - priceCum0) / (block.timestamp - t0);

        uint256 futureWeight = block.timestamp - t0;
        uint256 maxWeight = PERIOD;

        if(futureWeight > maxWeight) {
            update(); // May as well update
            // Return virtual
            return virtualAvgValue;
        }

        uint256 weightedAvg = avgValue * (maxWeight - futureWeight);
        uint256 weightedVirtual = virtualAvgValue * (futureWeight);

        uint256 weightedMean = (weightedAvg + weightedVirtual) / PERIOD;


        return weightedMean;
    }

    function update() public returns (uint256) {
        // On epoch flip, we update as intended
        if (block.timestamp >= t0 + PERIOD) {
            // Compute based on delta
            avgValue = (REFERENCE_TWAP.getLatestAccumulator() - priceCum0) / (block.timestamp - t0);

            // Then we update
            priceCum0 = REFERENCE_TWAP.getLatestAccumulator();
            t0 = block.timestamp;
        }
    }
}
