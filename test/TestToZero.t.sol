// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";


contract TwTap {

    uint256 public EPOCH_DURATION = 7 days;
    uint256 public constant MIN_WEIGHT_FACTOR = 1000; // In BPS, 0.1%

    uint256 public cumulative = EPOCH_DURATION;
    uint256 public totalDeposited = 0;
    uint256 public averageMagnitude = 0;

    uint256 public totalParticipants;

    uint256 public spent = 0;

    function participate(uint256 duration, uint256 amount) external returns (uint256) {
        require(duration > EPOCH_DURATION, "LockNotAWeek");

        // Transfer TAP to this contract
        spent += amount;

        uint256 magnitude = computeMagnitude(duration, cumulative); // This is just duration and prev
        // Revert if the lock 4x the cumulative||| But the impact of locking different weight should be counted in some way
        require(magnitude < cumulative * 4, "Magnitude too big");
        uint256 multiplier = computeTarget( // magnitude * dMax / cumulative | clamp(dMAX, dMin)
            1_000_000,
            100_000,
            magnitude, /// NOTE: Basically based on duration
            cumulative
        );

        // Calculate twAML voting weight
        bool divergenceForce;
        bool hasVotingPower = amount >=
            computeMinWeight(totalDeposited, MIN_WEIGHT_FACTOR);
        if (hasVotingPower) { /// @audit Not idempotent, ordering matters
            totalParticipants++; // Save participation
            averageMagnitude =
                (averageMagnitude + magnitude) /
                totalParticipants; // compute new average magnitude | // new Magnitude / total? /// @audit This is NOT average, looks OFF

            // Compute and save new cumulative
            divergenceForce = duration >= cumulative; /// if duration > SUM(prev_durations)

            if (divergenceForce) {
                cumulative += averageMagnitude;
            } else {
                // TODO: Strongly suspect this is never less. Prove it.
                if (cumulative > averageMagnitude) {
                    cumulative -= averageMagnitude;
                } else {
                    cumulative = 0;
                }
            }

            // Save new weight
            totalDeposited += amount;
        }

        return duration * multiplier;
    }

    function getMinWeight() external view returns (uint256) {
        return computeMinWeight(totalDeposited, MIN_WEIGHT_FACTOR);
    }

    function computeMinWeight(
        uint256 _totalWeight,
        uint256 _minWeightFactor
    ) internal pure returns (uint256) {
        uint256 mul = (_totalWeight * _minWeightFactor);
        return mul >= 1e4 ? mul / 1e4 : _totalWeight; /// @audit First few times this can be zero, if a small amount is locked
    }

    function computeMagnitude(
        uint256 _timeWeight,
        uint256 _cumulative
    ) internal pure returns (uint256) {
        return /// @audit Safe from overflow by definition sqrt(cum * cum) == cum
            sqrt(_timeWeight * _timeWeight + _cumulative * _cumulative) -
            _cumulative;
    } 

    function computeTarget(
        uint256 _dMin,
        uint256 _dMax,
        uint256 _magnitude,
        uint256 _cumulative
    ) internal pure returns (uint256) {
        if (_cumulative == 0) {
            return _dMax;
        }
        uint256 target = (_magnitude * _dMax) / _cumulative; /// @audit if magnituded / cum >= 1 -> dMax
        target = target > _dMax ? _dMax : target < _dMin ? _dMin : target;
        return target;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract ExampleTest is Test {
    function testToZero() public {
        TwTap twtap = new TwTap();

        // Reverse binary search on duration
        uint256 lastGoodDuration = twtap.EPOCH_DURATION() * 4;
        
        uint256 totalMultiplier;

        uint256 amt;
        uint256 duration;

        uint256 totalAmtNeeded;

        // Normal Lock
        twtap.participate(lastGoodDuration, 10_0000);
        console2.log("cumulative start", twtap.cumulative());

        // Smaller lock, proof we can drag down
        twtap.participate(lastGoodDuration / 2, 10_0000);
        console2.log("cumulative start", twtap.cumulative());

        // Drag down to theoretical minmum
        while(twtap.cumulative() > 604557) {
            twtap.participate(twtap.EPOCH_DURATION() + 1, 10_0000);
            console2.log("cumulative start", twtap.cumulative());
        }
    }
}
