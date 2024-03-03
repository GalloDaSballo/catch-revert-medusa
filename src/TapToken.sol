// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20} from "@oz/token/ERC20/ERC20.sol";

contract TapToken is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 46_686_595 * 1e18; // Everything minus DSO

    constructor() ERC20("Tapioca Token", "TAP") {}
    function mintToSelf(uint256 amt) external {
      _mint(msg.sender, amt);
      if(totalSupply() > INITIAL_SUPPLY) {
        revert ("Too Much");
      }
    }
}