pragma solidity ^0.4.24; 

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';
import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';

import './TwoKeyCampaignETH.sol';
import './TwoKeyReg.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyEventSource.sol';
import "./TwoKeyWhitelisted.sol";
import "./TwoKeyCampaignInventory.sol";

contract TwoKeyCampaignETHCrowdsale is TwoKeyCampaignETH, Crowdsale {

	using SafeMath for uint256;

	constructor(
		TwoKeyEventSource _eventSource,
		TwoKeyEconomy _economy,
		TwoKeyWhitelisted _whitelistInfluencer,
		TwoKeyWhitelisted _whitelistConverter,
//		TwoKeyCampaignInventory twoKeyCampaignInventory,

		address _contractor,
		address _moderator,


//		uint256 _start,
//		uint256 _duration,
		uint256 _expiryConversion,
		uint256 _escrowPrecentage,
		uint256 _rate,
		uint256 _maxPi) TwoKeyCampaign(
		_eventSource,
		_economy,
		_whitelistInfluencer,
		_whitelistConverter,
//		_composableAssetFactory,
		_contractor,
		_moderator,
//		_start,
//		_duration,
		_expiryConversion,
		_escrowPrecentage,
		_rate,
		_maxPi
	) public {
	}

	// buy product with ETH 
	function buyFromWithETH(address _from, uint256 _tokenID, address _assetContract, uint256 _amountOrIndex) public payable {
	    buyTokens(address(this));
	    require(twoKeyCampaignInventory.addFungibleAsset(_tokenID, _assetContract, _amountOrIndex));
	    buyFromWithETH(_from, _tokenID, _assetContract, _amountOrIndex, CampaignType.Fungible); 
	}	

}

