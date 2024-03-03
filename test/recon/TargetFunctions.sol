
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

abstract contract TargetFunctions is BaseTargetFunctions, Properties, BeforeAfter {

    function TapToken_approve(address spender, uint256 amount) public {
      
    }

    function TapToken_decreaseAllowance(address spender, uint256 subtractedValue) public {
      tap.decreaseAllowance(spender, subtractedValue);
    }

    function TapToken_increaseAllowance(address spender, uint256 addedValue) public {
      tap.increaseAllowance(spender, addedValue);
    }

    function TapToken_mintToSelf(uint256 amt) public {
      tap.mintToSelf(amt);
    }

    function TapToken_transfer(address to, uint256 amount) public {
      tap.transfer(to, amount);
    }

    function TapToken_transferFrom(address from, address to, uint256 amount) public {
      tap.transferFrom(from, to, amount);
    }



    // TODO: Rewards
    // function TwTAP_addRewardToken(address _token) public {
    //   twTap.addRewardToken(IERC20(_token));
    // }

    function TwTAP_advanceWeek(uint256 _limit) public {
      twTap.advanceWeek(_limit);
    }

    function TwTAP_approve(address to, uint256 tokenId) public {
      twTap.approve(to, tokenId);
    }

    function TwTAP_claimRewards(uint256 _tokenId, address _to) public {
      twTap.claimRewards(_tokenId, _to);
    }

    function TwTAP_distributeReward(uint256 _rewardTokenId, uint256 _amount) public {
      twTap.distributeReward(_rewardTokenId, _amount);
    }

    function TwTAP_exitPosition(uint256 _tokenId, address _to) public {
      twTap.exitPosition(_tokenId, _to);
    }

    function TwTAP_participate(address _participant, uint256 _amount, uint256 _duration) public {
      _duration = between(_duration, twTap.EPOCH_DURATION(), twTap.MAX_LOCK_DURATION());
      twTap.participate(_participant, _amount, _duration);
    }

    function TwTAP_renounceOwnership() public {
      twTap.renounceOwnership();
    }

    function TwTAP_safeTransferFrom(address from, address to, uint256 tokenId) public {
      twTap.safeTransferFrom(from, to, tokenId);
    }

    function TwTAP_safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
      twTap.safeTransferFrom(from, to, tokenId, data);
    }

    function TwTAP_setApprovalForAll(address operator, bool approved) public {
      twTap.setApprovalForAll(operator, approved);
    }

    function TwTAP_setMaxRewardTokensLength(uint256 _length) public {
      twTap.setMaxRewardTokensLength(_length);
    }

    function TwTAP_setMinWeightFactor(uint256 _minWeightFactor) public {
      twTap.setMinWeightFactor(_minWeightFactor);
    }

    function TwTAP_setVirtualTotalAmount(uint256 _virtualTotalAmount) public {
      twTap.setVirtualTotalAmount(_virtualTotalAmount);
    }

    function TwTAP_transferFrom(address from, address to, uint256 tokenId) public {
      twTap.transferFrom(from, to, tokenId);
    }

    function TwTAP_transferOwnership(address newOwner) public {
      twTap.transferOwnership(newOwner);
    }
}
