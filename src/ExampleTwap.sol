// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

contract ExampleTwap {
    uint256 public accumulator;
    uint256 public lastUpdate;

    uint256 public valueToTrack;

    constructor(uint256 initialValue) {
        // Update to last value from beginning
        // The first value is basically insanely strong
        valueToTrack = initialValue;
        accumulator = 0 * block.timestamp;
    }

    // Set to new value, sync accumulator to now with old value
    // Changes in same block have no impact, as no time has expired
    // Effectively we use the previous block value, and we magnify it by weight
    function setValue(uint256 newValue) external {
        _updateAcc(valueToTrack);

        lastUpdate = block.timestamp;
        valueToTrack = newValue;
    }

    // Update the accumulator based on time passed
    function _updateAcc(uint256 oldValue) internal {
        accumulator += oldValue * (timeToAccrue());
    }

    function timeToAccrue() public view returns (uint256) {
        return block.timestamp - lastUpdate;
    }

    // Return the update value to now
    function _syncToNow(uint256 oldValue) internal view returns (uint256) {
        return accumulator + (valueToTrack * (timeToAccrue()));
    }

    // == Getters == //
    function getRealValue() public view returns (uint256) {
        return valueToTrack;
    }

    function getLatestAccumulator() public view returns (uint256) {
        return _syncToNow(valueToTrack);
    }
}
