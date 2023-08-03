function calc_stable_lp_price(
		address vmexOracle,
		address bal_pool, 
		bool legacy
	) internal returns (uint256) {	
		IBalancer pool = IBalancer(bal_pool);

        // get the underlying assets
        IVault vault = IBalancer(bal_pool).getVault();
        bytes32 poolId = IBalancer(bal_pool).getPoolId();


        (
            IERC20[] memory tokens,
            ,
        ) = vault.getPoolTokens(poolId);
		
		uint256 bptIndex;
		// if(legacy) {
		// 	bptIndex = type(uint256).max;
		// } else {
		// 	bptIndex = pool.getBptIndex();
		// }
		try pool.getBptIndex() returns (uint ind) {
			bptIndex = ind;
		} catch {
			bptIndex = type(uint256).max;
		}

		uint256 minPrice = type(uint256).max;

		address[] memory rateProviders;
		if(legacy) {
			rateProviders = pool.getRateProviders();
		} 

		for (uint256 i = 0; i < tokens.length; i++) {
			if (i == bptIndex) {
				continue;
			}
			// Get the price of each of the base tokens in ETH
			// This also includes the price of the nested LP tokens, if they are e.g. LinearPools
			// The only requirement is that the nested LP tokens have a price oracle registered
			// See BalancerLpLinearPoolPriceOracle.sol for an example, as well as the relevant tests
			uint256 price = IPriceOracle(vmexOracle).getAssetPrice(address(tokens[i]));
			uint256 depositTokenPrice;
			if(legacy) {
				if(rateProviders[i] == address(0)){
					depositTokenPrice = 1e18;
				} else {
					depositTokenPrice = IRateProvider(rateProviders[i]).getRate();
				}
			} else {
				depositTokenPrice = pool.getTokenRate(address(tokens[i]));
			}
			uint256 finalPrice = (price * 1e18) / depositTokenPrice; //rate always yas 18 decimals, so this preserves original decimals of price
			if (finalPrice < minPrice) {
				minPrice = finalPrice;
			}
		}
		// Multiply the value of each of the base tokens' share in ETH by the rate of the pool
		// pool.getRate() is the rate of the pool, scaled by 1e18
		return (minPrice * pool.getRate()) / 1e18; // Attackable if it costs less than this to join and get 1 token
	}