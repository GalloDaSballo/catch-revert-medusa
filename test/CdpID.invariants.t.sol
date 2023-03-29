// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Test} from "forge-std/Test.sol";


contract CDPID is Test {
    function setUp() public {
    }

    function testCombo(address one, address two, uint256 blockOne, uint256 nonceOne, uint256 blockTwo, uint256 nonceTwo) public {
        vm.assume(one != two);

        blockOne += 16933051;
        blockTwo += 16933051;
        blockOne = blockOne % 25955150000;
        blockTwo = blockTwo % 25955150000;

        bool eq = toCdpId(one, blockOne, nonceOne) == toCdpId(two, blockTwo, nonceTwo);
        assertTrue(!eq);
    }
    function toCdpId(
        address owner,
        uint256 blockHeight,
        uint256 nonce
    ) public pure returns (bytes32) {
        bytes32 serialized;

        serialized |= bytes32(nonce);
        serialized |= bytes32(blockHeight) << (8 * 8); // to accommendate more than 4.2 billion blocks
        serialized |= bytes32(uint256(owner)) << (12 * 8);

        return serialized;
    }
}
