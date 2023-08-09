
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

contract HACK {
   
    address[] public owners = [address(3),address(5)];

   function tryy( ) public {
        delete owners;
       address[] storage a = owners;

       a.push(address(9));
       a.push(address(7));
       
   }

}

contract CompoundedStakesFuzz is Test {
    HACK e;
    function setUp() public {
        e = new HACK();
    }
    function testCompareOne() public {
        e.tryy();
        console2.log("e", e.owners(0));
        console2.log("e", e.owners(1));
        console2.log("e", e.owners(2));
        console2.log("e", e.owners(3));
    }

}
