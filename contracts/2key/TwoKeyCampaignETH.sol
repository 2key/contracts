pragma solidity ^0.4.24;

import "./TwoKeyTypes.sol";
import "./TwoKeyAcquisitionCampaignERC20.sol";


contract TwoKeyCampaignETH is TwoKeyAcquisitionCampaignERC20 {
 
	/*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH 
	    transfers to the escrow the asset purchased
    */

	// tokenID, asset contract, sufficient
	//
	function fulfillFungibleETH(
		address _from, 
		string _assetName, //no need
		address _assetContract, //no need
		uint256 _amount) isOngoing internal {
		// TODO: Idea is that payout is msg.value
		// Compute for the amount of ether how much tokens can be got by the amount
		require(_amount > 0 && price > 0);
		uint256 payout = price.mul(_amount);
		require(msg.value == payout);
		//TODO: Someone put 100 eth and he's entitled to X base + Y bonus  = (X+Y) taken from Inventory
		//TODO: Take the msg.value, and regarding value I compute number of base and bonus tokens - sum of base and bonus is took out of the twoKeyCampaignInvent
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE, now, now + expiryConversion * 1 days);


		// move funds
		// rename to remove from inventory
		campaign_balance = campaign_balance - _amount;
//		removeFungibleAssets(_tokenID, _assetContract, _amount);


		//tokenID can be string specifying the name of token ("ETH", "BTC",etc)
		// value in escrow (msg.value), total amount of tokens
		twoKeyEventSource.escrow(address(this), msg.sender, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE);
		conversions[msg.sender] = c;
	}

    /*  
	    fulfills a non fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH
	    transfers to the escrow the asset purchased
    */
//	function fulfillNonFungibleETH(address _from, uint256 _tokenID, address _assetContract, uint256 _index) isOngoing internal {
//		address assetToken = address(
//	      keccak256(abi.encodePacked(_assetContract, _index))
//	    );
//		require(_index != 0 && price > 0);
//		uint256 payout = price;
//		require(msg.value == payout);
//		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _assetContract, _index, CampaignType.NonFungible, now, now + expiryConversion * 1 days);
//		twoKeyEventSource.escrow(address(this), msg.sender, _tokenID, _assetContract, _index, CampaignType.NonFungible);
//		conversions[msg.sender] = c;
//	}

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
		twoKeyEventSource.fulfilled(address(this), c.converter, c.assetName, c.assetContract, c.amount, c.campaignType);
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
		string _assetName,
		address _assetContract, 
		uint256 _amountOrIndex,
		CampaignType _campaignType) public payable {
		if (_campaignType == CampaignType.CPA_FUNGIBLE) {
			fulfillFungibleETH(_from, _assetName, _assetContract, _amountOrIndex);
		} else if (_campaignType == CampaignType.CPA_NON_FUNGIBLE) {
//			fulfillNonFungibleETH(_from, _tokenID, _assetContract, _amountOrIndex);
		} 
	}

}

