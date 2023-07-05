contract CropJoin {
      function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }

    uint256 total;
    uint256 balance;

    function deposit(uint256 thusdAmount) external {        
        // update share
        uint256 thusdValue = balance;

        uint256 totalValue = thusdValue;

        // this is in theory not reachable. if it is, better halt deposits
        // the condition is equivalent to: (totalValue = 0) ==> (total = 0)
        require(totalValue > 0 || total == 0, "deposit: system is rekt");

        uint256 newShare = _toShares(total, totalValue, true);

        // update LP token

        total += newShare;

        emit UserDeposit(msg.sender, thusdAmount, newShare);        
    }

    function withdraw(uint256 numShares) external {
        uint256 thusdValue = SP.getCompoundedTHUSDDeposit(address(this));
        uint256 collateralValue = getCollateralBalance();

        uint256 thusdAmount = numShares._toAmount(total, thusdValue, true);
        uint256 collateralAmount = numShares._toAmount(total, collateralValue, false);

        // this withdraws thusdn and collateral
        SP.withdrawFromSP(thusdAmount);

        // update LP token
        burn(msg.sender, numShares);

        // send thusd and collateral
        if(thusdAmount > 0) thusdToken.transfer(msg.sender, thusdAmount);
        emit UserWithdraw(msg.sender, thusdAmount, collateralAmount, numShares);        
        if(collateralAmount == 0) {
            return;
        }

        sendCollateral(collateralERC20, msg.sender, collateralAmount);
    }
}