pragma solidity ^0.4.24; 

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

import './CrowdsaleWithTwoKey.sol';
import './TwoKeyCampaign.sol';
import './TwoKeyReg.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyWhitelisted.sol';
import './TwoKeyEventSource.sol';

contract TwoKeyCampaignCrowdsale is TwoKeyCampaign {

	using SafeMath for uint256;

	CrowdsaleWithTwoKey crowdsale;

	uint256 bonus;

	constructor(
		uint256 _bonus,
		CrowdsaleWithTwoKey _crowdsale,
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
		bonus = _bonus;
		crowdsale = _crowdsale;
	}

  	// buy product with twokey token
	function buyFromWithTwoKey(address _from, uint256 _tokenID, address _childContract, uint256 _amountOrIndex) public payable {
	    crowdsale.buyTokens.value(msg.value)(address(this));
	    require(addFungibleChild(_tokenID, _childContract, _amountOrIndex.mul(bonus)));
	    super.buyFromWithTwoKey(_from, _tokenID, _childContract, _amountOrIndex);
	}	

}

