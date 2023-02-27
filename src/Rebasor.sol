// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract FakeRebasableETH {
    uint256 public totalBalance;
    uint256 public totalShares; // All issued shares
    mapping(address => uint256) public sharesOf; // All issued shares

    // shares[account] * _getTotalPooledEther() / _getTotalShares()

    function getSharesByPooledEth(uint256 ethAmount) public view returns (uint256) {
        if(totalBalance == 0) {
            return ethAmount;
        }
        return ethAmount * totalShares / totalBalance;
    }
    function getPooledEthByShares(uint256 sharesAmount) public view returns (uint256) {
        return sharesAmount * totalBalance / totalShares;
    }

    function addUnderlying(uint256 value) external {
        totalBalance += value;
    }

    function removeUnderlying(uint256 value) external {
        totalBalance -= value;
    }

    function depositAndMint(uint256 value) external returns (uint256 minted) {
        minted = getSharesByPooledEth(value);
        totalBalance += value;
        totalShares += minted;

        sharesOf[msg.sender] += minted;
    }

    function balanceOf(address acc) external view returns (uint256) {
        return getPooledEthByShares(sharesOf[acc]);
    }
}

contract Rebasor {
    FakeRebasableETH public immutable STETH;

    uint256 public stFFPSg; // Global Index

    uint256 public allShares;

    mapping(address => uint256) public sharesDeposited;
    mapping(address => uint256) public stFFPScdp;

    uint256 lastFeeIndex;

    // 50%
    uint256 constant public FEE = 5_000;
    uint256 constant public MAX_BPS = 10_000;


    /**
        Learnings
            Total Shares and Total Balance could be packed into one var (128 + 128)
            This avoids rounding issues later
     */

    constructor() public {
        STETH = new FakeRebasableETH();
    }

    function deposit(uint256 amt) external {
        allShares += amt;
        sharesDeposited[msg.sender] += amt;
        
        uint256 cachedIndex = STETH.getPooledEthByShares(1e18);
        // Index of deposit
        stFFPScdp[msg.sender] = cachedIndex;

        // Global index
        stFFPSg = cachedIndex;
    }

    function collateralCDP(address cdp) external view returns (uint256) {
        uint256 newIndex = STETH.getPooledEthByShares(1e18);
        uint256 originalDeposit = sharesDeposited[msg.sender];
        uint256 cachedIndex = stFFPScdp[msg.sender];

        // Early return if no change
        if(newIndex == cachedIndex) {
            return originalDeposit * cachedIndex / 1e18;
        }

        // Handle change, add fees to delta and return new coll
        if(newIndex > cachedIndex) {
            // Handle Profit
            uint256 indexAfterFees = getIndexAfterFees(originalDeposit, cachedIndex, newIndex);
            return originalDeposit * indexAfterFees / 1e18;

        } else if (newIndex < cachedIndex) {
            // Handle Slashing
            uint256 indexAfterSlash = getIndexAfterSlash(originalDeposit, cachedIndex, newIndex);
            return originalDeposit * indexAfterSlash / 1e18;
        }
    }

    function getIndexAfterFees(uint256 cdpValue, uint256 prevIndex, uint256 newIndex) public view returns (uint256) {
        require(newIndex > prevIndex);

        uint256 deltaIndex = newIndex - prevIndex;
        uint256 deltaIndexFees = deltaIndex * FEE / MAX_BPS;

        uint256 deltaIndexAfterFees = deltaIndex - deltaIndexFees;
        uint256 newRebaseIndex = prevIndex + deltaIndexAfterFees;

        return newRebaseIndex;
    }

    function getIndexAfterSlash(uint256 cdpValue, uint256 prevIndex, uint256 newIndex) public view returns (uint256) {
        require(prevIndex > newIndex);

        return newIndex;
    }



    function getGrowthAfterFees() external {

    }

    function getValueAtCurrentIndex() external view returns (uint256) {

    }

    function getValueAfterFees() external view returns (uint256) {

    }
}
