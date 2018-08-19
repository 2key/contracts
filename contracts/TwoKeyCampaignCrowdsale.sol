pragma solidity ^0.4.24; 

import './openzeppelin-solidity/contracts/math/SafeMath.sol';
import './openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';

import './TwoKeyCampaign.sol';
import './TwoKeyReg.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyWhitelisted.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyTypes.sol';

contract TwoKeyCampaignCrowdsale is TwoKeyCampaign, Crowdsale {

	using SafeMath for uint256;

	constructor(
		TwoKeyEventSource _eventSource,
		TwoKeyEconomy _economy,
		TwoKeyWhitelisted _whitelistInfluencer,
		TwoKeyWhitelisted _whitelistConverter, 
		 
		address _contractor,
		address _moderator, 

		
		uint256 _start,
		uint256 _duration,
		uint256 _expiryConversion, 
		uint256 _escrowPrecentage,
		uint256 _rate,
		uint256 _maxPi) TwoKeyCampaign(
		_eventSource,
		_economy,
		_whitelistInfluencer,
		_whitelistConverter,  
		_contractor,
		_moderator, 		
		_start,
		_duration,
		_expiryConversion, 
		_escrowPrecentage,
		_rate,
		_maxPi) public {
	}

  	// buy product with twokey token
	function buyFromWithTwoKey(address _from, uint256 _tokenID, address _assetContract, uint256 _amountOrIndex) public payable {
	    buyTokens.value(msg.value)(address(this));
	    require(addFungibleAsset(_tokenID, _assetContract, _amountOrIndex));
	    super.buyFromWithTwoKey(_from, _tokenID, _assetContract, _amountOrIndex, CampaignType.Fungible);
	}	

}

