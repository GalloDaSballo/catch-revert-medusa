// SPDX-License Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "forge-std/console2.sol";


contract DumbContract {
    function fallback() {
        require(gasleft() )
    }
}

contract ExampleTest is Test {

}
