
// SPDX-License Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract EventEmitter {
    event CdpCreated (
        bytes32 indexed id,
        address indexed borrower,
        address indexed creator,
        uint256 arrayIndex
    );

    event CdpUpdated (
        bytes32 indexed id,
        address indexed borrower,
        uint256 d,
        uint256 c,
        uint256 d2,
        uint256 c2,
        uint256 s,
        uint8 operation
    );

    function onlyOne() public {
        emit CdpCreated(bytes32(abi.encode(123)), address(123), address(123), 123);
    }
    function both() public {
        emit CdpCreated(bytes32(abi.encode(123)), address(123), address(123), 123);
        emit CdpUpdated(bytes32(abi.encode(123)), address(123), 123, 123, 123, 123, 123, 1);
    }
}

contract CompoundedStakesFuzz is Test {
    EventEmitter e;
    function setUp() public {
        e = new EventEmitter();
    }
    function testCompareOne() public {
        e.onlyOne();
    }

    function testCompareTwo() public {
        e.both();
    }
}
