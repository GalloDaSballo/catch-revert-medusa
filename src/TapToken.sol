import {ERC20} from "@oz/token/ERC20/ERC20.sol";

contract TapToken is ERC20 {
    uint256 public constant INITIAL_SUPPLY = 46_686_595 * 1e18; // Everything minus DSO

    function mintToSelf(uint256 amt) {
      _mint(msg.sender, amt);
      if(totalSupply() > INITIAL_SUPPLY) {
        revert ("Too Much");
      }
    }
}