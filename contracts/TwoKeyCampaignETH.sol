pragma solidity ^0.4.24;

import './TwoKeyEscrow.sol';
import './TwoKeyCampaign.sol';


contract TwoKeyCampaignETH is TwoKeyCampaign {
 
	/*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillFungibleETH(address _from, uint256 _tokenID, address _childContract, uint256 _amount) isOngoing internal {	
		require(_amount > 0 && prices[_tokenID][_childContract] > 0);
		uint256 payout = prices[_tokenID][_childContract].mul(_amount);
		require(msg.value == payout);
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _childContract, _amount, CampaignType.Fungible);
		// move funds
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, contractor, moderator, msg.sender, now, expiryConversion, whitelistConverter);
		transferFungibleChild(esc, _tokenID, _childContract, _amount);
		eventSource.escrow(address(this), esc, msg.sender, _tokenID, _childContract, _amount, CampaignType.Fungible);
		conversions[address(esc)] = c;
	}

    /*  
	    fulfills a non fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout in ETH
	    transfers to the escrow the asset purchased
    */
	function fulfillNonFungibleETH(address _from, uint256 _tokenID, address _childContract, uint256 _index) isOngoing internal {	
		address childToken = address(
	      keccak256(abi.encodePacked(_childContract, _index))
	    );
		require(_index != 0 && prices[_tokenID][childToken] > 0);
		uint256 payout = prices[_tokenID][childToken];
		require(msg.value == payout);
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _childContract, _index, CampaignType.NonFungible);
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, contractor, moderator, msg.sender, now, expiryConversion, whitelistConverter);
		transferNonFungibleChild(esc, _tokenID, _childContract, _index);
		eventSource.escrow(address(this), esc, msg.sender, _tokenID, _childContract, _index, CampaignType.NonFungible);
		conversions[address(esc)] = c;
	}

    /**
     * called when we heard the escrow was fulfilled
     * calculates moderetor fee, pays the moderator, 
     * computes total reward
     * transfer payout to buyer, deducting the fee and the total reward
     * asks the campaign to distribute rewards to influencers
     */

	function actuallyFulfilledTwoKeyToken(TwoKeyEscrow esc) onlyOwner public {
		Conversion memory c = conversions[address(esc)];
		require(!c.isFulfilled && !c.isCancelled);
		uint256 fee = calculateModeratorFee(c.payout);
        moderator.transfer(fee); 
        uint256 payout = c.payout;
        uint256 maxReward = maxPi.mul(payout).div(100);
        
        // transfer payout - fee - rewards to seller
        contractor.transfer(payout.sub(fee).sub(maxReward));
        
        transferRewardsTwoKeyToken(c.from, maxReward.mul(rate));
        eventSource.fulfilled(address(this), c.buyer, c.tokenID, c.childContract, c.indexOrAmount, c.campaignType);
	}

	/**
  	 * buy product withETH, 
  	 * _from is the influencer from which you received the referral
  	 * _tokenID is the asset sku
  	 * _childContract - erc20 (fungible) or erc721 (non fungible) which represents the class of the asset
  	 * _amountOrIndex - for erc20 amount in asset class, for erc21 index within asset class
  	 */
	function buyFromWithETH(address _from, uint256 _tokenID, address _childContract, uint256 _amountOrIndex) public payable {
	    buyProductETH(_from, _tokenID, _childContract, _amountOrIndex); 
	}

	// internal function that splits the treatment for fungible or non fungible
	function buyProductETH(address _from, uint256 _tokenID, address _childContract, uint256 _amountOrIndex) internal {
		CampaignType campaignType = getType(_tokenID);
		if (campaignType == CampaignType.Fungible) {
			fulfillFungibleETH(_from, _tokenID, _childContract, _amountOrIndex);
		} else if (campaignType == CampaignType.NonFungible) {
			fulfillNonFungibleETH(_from, _tokenID, _childContract, _amountOrIndex);
		} 
	}

}

