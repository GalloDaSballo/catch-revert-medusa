// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {CallTestAndUndo} from "src/CallTestAndUndo.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

contract CryticToFoundry is Test, CallTestAndUndo {
    function setUp() public {

    }


    // Never called directly because we don't want it to be state changing
    /// Virtual Contract
    function echidna_123(uint256 paramA) public virtual returns (bool) {
      // NOTE: we can soft enforce calling self via try catch by overriding all of them in a parent contract

      // t(false); // TODO: Assert these can never be called directly

      return true;
    }

    function callThatReverts(uint256 param) public virtual returns (bool) {
      revert("asd");
    }
    function callThatFails(uint256 param) public virtual returns (bool) {
      return false;
    }
    function callThatPasses(uint256 param) public virtual returns (bool) {
      return true;
    }


    function doCallThatReverts(uint256 paramB) public returns (bool) {
      
      bytes memory encoded = abi.encodeCall(this.callThatReverts, (paramB));
      bool asBool = _doTestAndReturnResult(encoded);

      return asBool;
    }

    function doCallThatFails(uint256 paramB) public returns (bool) {
      
      bytes memory encoded = abi.encodeCall(this.callThatFails, (paramB));
      bool asBool = _doTestAndReturnResult(encoded);

      return asBool;
    }

    function doCallThatPasses(uint256 paramB) public returns (bool) {
      
      bytes memory encoded = abi.encodeCall(this.callThatPasses, (paramB));
      bool asBool = _doTestAndReturnResult(encoded);

      return asBool;
    }


    

    ////////////////
    function testLibrarySuccess() public {
      // Success returns true
      assertTrue(doCallThatPasses(123), "Success must be true");
    }
    function testLibraryRevert() public {
      /// Revert is viewed as success
      assertTrue(doCallThatReverts(123), "Revert must succeed");
    }

    function testLibraryFailure() public {
      /// Revert is viewed as success
      assertFalse(doCallThatFails(123), "Failure must be false");
    }
}
