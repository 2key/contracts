pragma solidity ^0.4.24;

import './TwoKeyCampaign.sol';


contract TwoKeyCampaignETH is TwoKeyCampaign {
 
	/*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH 
	    transfers to the escrow the asset purchased
    */
	//isOngoing -commented
	function fulfillFungibleETH(
		address _from, 
		uint256 _tokenID, 
		address _assetContract, 
		uint256 _amount) internal {
		require(_amount > 0 && prices[_tokenID][_assetContract] > 0);
		uint256 payout = prices[_tokenID][_assetContract].mul(_amount);
		require(msg.value == payout);
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _assetContract, _amount, CampaignType.Fungible, now, now + expiryConversion * 1 days);
		// move funds
		composableAssetFactory.remAssets(_tokenID, _assetContract, _amount);
		eventSource.escrow(address(this), msg.sender, _tokenID, _assetContract, _amount, CampaignType.Fungible);
		conversions[msg.sender] = c;
	}

    /*  
	    fulfills a non fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH
	    transfers to the escrow the asset purchased
    */
	// isOngoing - commented
	function fulfillNonFungibleETH(address _from, uint256 _tokenID, address _assetContract, uint256 _index) internal {
		address assetToken = address(
	      keccak256(abi.encodePacked(_assetContract, _index))
	    );
		require(_index != 0 && prices[_tokenID][assetToken] > 0);
		uint256 payout = prices[_tokenID][assetToken];
		require(msg.value == payout);
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _assetContract, _index, CampaignType.NonFungible, now, now + expiryConversion * 1 days);
		eventSource.escrow(address(this), msg.sender, _tokenID, _assetContract, _index, CampaignType.NonFungible);
		conversions[msg.sender] = c;
	}

    /**
     * calculates moderetor fee, pays the moderator, 
     * computes total reward
     * transfer payout to buyer, deducting the fee and the total reward
     * asks the campaign to distribute rewards to influencers
     */

	function actuallyFulfilledTwoKeyToken() internal {
		Conversion memory c = conversions[msg.sender];
        c.isFulfilled = true; 
        conversions[msg.sender] = c;
		uint256 fee = calculateModeratorFee(c.payout);
        moderator.transfer(fee); 
        uint256 payout = c.payout;
        uint256 maxReward = maxPi.mul(payout).div(100);
        
        // transfer payout - fee - rewards to seller
        contractor.transfer(payout.sub(fee).sub(maxReward));
        
        transferRewardsTwoKeyToken(c.from, maxReward.mul(rate));
        eventSource.fulfilled(address(this), c.converter, c.tokenID, c.assetContract, c.indexOrAmount, c.campaignType);
	}

	/**
  	 * buy product withETH, 
  	 * _from is the influencer from which you received the referral
  	 * _tokenID is the asset sku
  	 * _assetContract - erc20 (fungible) or erc721 (non fungible) which represents the class of the asset
  	 * _amountOrIndex - for erc20 amount in asset class, for erc21 index within asset class
  	 */
	function buyFromWithETH(
		address _from, 
		uint256 _tokenID, 
		address _assetContract, 
		uint256 _amountOrIndex,
		CampaignType _campaignType) public payable {
		if (_campaignType == CampaignType.Fungible) {
			fulfillFungibleETH(_from, _tokenID, _assetContract, _amountOrIndex);
		} else if (_campaignType == CampaignType.NonFungible) {
			fulfillNonFungibleETH(_from, _tokenID, _assetContract, _amountOrIndex);
		} 
	}

}

