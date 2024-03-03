
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {BaseSetup} from "@chimera/BaseSetup.sol";

import "src/TapToken.sol";
import "src/TwTAP.sol";

abstract contract Setup is BaseSetup {

    TapToken tap;
    TwTAP twTap;

    function setup() internal virtual override {

      tap = new TapToken();
      twTap = new TwTAP(payable(address(tap))); // TODO: Add parameters here

      tap.mintToSelf(tap.INITIAL_SUPPLY() - 1);
      tap.approve(address(twTap), type(uint256).max);
    }
}
