
// SPDX-License Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract CompoundedStakesFuzz is Test {

    struct Snapshots {
        uint256 S;
        uint256 P;
        uint128 scale;
        uint128 epoch;
    }

    uint256 constant DECIMAL_PRECISION = 1e18;
    uint256 constant SCALE_FACTOR = 1e9;

    uint128 currentEpoch;
    uint128 currentScale;
    uint256 P;

    function setUp() public {}

    function test_compoundedStake(uint256 initialStakeTimesP, uint128 _currentEpoch, uint128 _currentScale, uint256 _P, uint256 S) public {
        
       _P = _P % DECIMAL_PRECISION;
       if(_P == 0){
        _P = 1;
       }
       console2.log("_P");
        /* This is an artifact I had to create so that there were no overflow reverts
         * due to initialStake and P being too big
         */

        uint256 initialStake = initialStakeTimesP/_P;
        currentEpoch = _currentEpoch;
        currentScale = _currentScale;
        P = _P;

        uint256 compoundedStake = _getCompoundedStakeFromSnapshots(
            initialStake,
            Snapshots(
                S,
                P,
                uint128(currentScale),
                uint128(currentEpoch)
            )
        );

        if (compoundedStake < initialStake / 1e9) {
            assertEq(compoundedStake, 0);
        }
    }

    // Straight up copied the function and commented out `if (compoundedStake < initialStake / 1e9) {return 0;}`
    function _getCompoundedStakeFromSnapshots(
        uint256 initialStake,
        Snapshots memory snapshots
    )
        internal
        view
        returns (uint)
    {
        uint256 snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) { return 0; }

        uint256 compoundedStake;
        uint128 scaleDiff = currentScale - scaleSnapshot;
        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
        * account for it. If more than one scale change was made, then the stake has decreased by a factor of
        * at least 1e-9 -- so return 0.
        */
        if (scaleDiff == 0) {
            compoundedStake = initialStake * P / snapshot_P;
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake * P / snapshot_P / SCALE_FACTOR;
        } else { // if scaleDiff >= 2
            compoundedStake = 0;
        }
        /*
        * If compounded deposit is less than a billionth of the initial deposit, return 0.
        *
        * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
        * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
        * than it's theoretical value.
        *
        * Thus it's unclear whether this line is still really needed.
        */
        // if (compoundedStake < initialStake / 1e9) {return 0;}

        return compoundedStake;
    }
}