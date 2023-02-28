// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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

// https://gist.github.com/rayeaster/99402460c7f990a70594e5b1a697ed88
contract Rebasor {
    FakeRebasableETH public immutable STETH;

    uint256 public stFFPSg; // Global Index
    uint256 public stFeePerUnitg = 1e18; // Global Fee accumulator per stake unit

    uint256 public allShares;
    uint256 public allStakes;
	
    mapping(address => uint256) public sharesDeposited;
	
    mapping(address => uint256) public stakes;
    
    mapping(address => uint256) public stFFPScdp;
	
    mapping(address => uint256) public stFeePerUnitcdp;

    uint256 lastFeeIndex;
    uint256 lastIndexTimestamp;
    uint256 constant public INDEX_UPD_INTERVAL = 43200; // 12 hours

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
        lastIndexTimestamp = block.timestamp;
    }

    function deposit(uint256 amt) external {
        // suppose we are deposit share directly
        uint _stake = _computeNewStake(amt);
		
        allShares += amt;
        sharesDeposited[msg.sender] += amt;
		
        allStakes += _stake;
        stakes[msg.sender] += _stake;
        
        uint256 cachedIndex = STETH.getPooledEthByShares(1e18);
        // Index of deposit
        stFFPScdp[msg.sender] = cachedIndex;
        stFeePerUnitcdp[msg.sender] = stFeePerUnitg;

        // Global index
        stFFPSg = cachedIndex;
    }

    function collateralCDP(address cdp) external returns (uint256) {
        uint256 newIndex = STETH.getPooledEthByShares(1e18);
        uint256 originalDeposit = sharesDeposited[msg.sender];
        uint256 cachedIndex = stFFPScdp[msg.sender];

        // Early return if no change
        if(newIndex == cachedIndex) {
            return _getUnderlyingFromShare(originalDeposit, cachedIndex);
        }

        // Handle change, add fees to delta and return new coll
        if(newIndex > cachedIndex) {
            // Handle Profit
            getIndexAfterFees(cachedIndex, newIndex);
            // update collateral for the CDP
            _updateCdpAfterFee(cdp);
        } else if (newIndex < cachedIndex) {
            // Handle Slashing
            getIndexAfterSlash(cachedIndex, newIndex);
        }
        return _getUnderlyingFromShare(sharesDeposited[msg.sender], newIndex);
    }

    // update global index and accumulator when there is a staking reward to split as fee
    function getIndexAfterFees(uint256 prevIndex, uint256 newIndex) public {
        require(newIndex > prevIndex);		
        require(block.timestamp - lastIndexTimestamp > INDEX_UPD_INTERVAL, "!updateTooFrequent");

        uint256 deltaIndex = newIndex - prevIndex;
        uint256 deltaIndexFees = deltaIndex * FEE / MAX_BPS;

//        uint256 deltaIndexAfterFees = deltaIndex - deltaIndexFees;
//        uint256 newRebaseIndex = prevIndex + deltaIndexAfterFees;

        // we take the fee for all CDPs immediately and update the global index/accumulator
        uint256 _deltaFeeSplit = deltaIndexFees * allShares / 1e18;
        uint256 _deltaFeeSplitShare = _deltaFeeSplit * STETH.getSharesByPooledEth(1e18) / 1e18;
        uint256 _deltaPerUnit = _deltaFeeSplitShare * 1e18 / allStakes;
        require(_deltaPerUnit > 0, "!feePerUnit");
        stFeePerUnitg += _deltaPerUnit;		
        stFFPSg = newIndex;
        lastIndexTimestamp = block.timestamp;
        require(allShares > _deltaFeeSplitShare, "!tooBigFee");
        allShares -= _deltaFeeSplitShare;
    }

    // update global index when there is a staking slash
    function getIndexAfterSlash(uint256 prevIndex, uint256 newIndex) public {
        require(prevIndex > newIndex);		
        require(block.timestamp - lastIndexTimestamp > INDEX_UPD_INTERVAL, "!updateTooFrequent");
        stFFPSg = newIndex;
        lastIndexTimestamp = block.timestamp;
    }

    function getGrowthAfterFees() external {

    }

    function getValueAtCurrentIndex() external view returns (uint256) {

    }

    function getValueAfterFees() external view returns (uint256) {

    }
	
    function _updateCdpAfterFee(address cdp) internal {
        uint _oldStake = stakes[cdp];	
        uint _feeSplitDistributed = _oldStake * (stFeePerUnitg - stFeePerUnitcdp[cdp]) / 1e18;
        require(sharesDeposited[cdp] > _feeSplitDistributed, "!tooBigFeeForCDP");
        sharesDeposited[cdp] -= _feeSplitDistributed;
        stFeePerUnitcdp[cdp] = stFeePerUnitg;

        uint _newStake = _computeNewStake(sharesDeposited[cdp]);
        allStakes += _newStake;
        allStakes -= _oldStake;
        stakes[cdp] = _newStake;
    }
	
    function _computeNewStake(uint _deposit) internal view returns (uint) {
        uint stake;
        if (allShares == 0) {
            stake = _deposit;
        } else {
            stake = _deposit * allStakes / allShares;
        }
        return stake;
    }
	
    function _getUnderlyingFromShare(uint _share, uint _index) internal view returns (uint){
        return _share * _index / 1e18;
    }
}
