pragma solidity ^0.4.24; 

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

import './TwoKeyCampaignETH.sol';
import './TwoKeyReg.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyEventSource.sol';
import "./TwoKeyWhitelisted.sol";
import "./TwoKeyCampaignInventory.sol";

/// TODO : Do we need crowdsale contract?
contract TwoKeyCampaignETHCrowdsale is TwoKeyCampaignETH {
//
//	using SafeMath for uint256;
//
//	constructor(
//		address _eventSource,
//		address _economy,
//		address _whitelistInfluencer,
//		address _whitelistConverter,
//
//		address _moderator,
//
//
//		uint256 _start,
//		uint256 _duration,
//		uint256 _expiryConversion,
//		uint256 _escrowPrecentage,
//		uint256 _rate,
//		uint256 _maxPi,
//		address _assetContract,
//		uint _quota) TwoKeyAcquisitionCampaignERC20(
//		_eventSource,
//		_economy,
//		_whitelistInfluencer,
//		_whitelistConverter,
//		_moderator,
//		_start,
//		_duration,
//		_expiryConversion,
//		_escrowPrecentage,
//		_rate,
//		_maxPi,
//		_assetContract,
//		_quota
//	) public {
//	}
//
//	// buy product with ETH
//	// We don't need tokenID since campaign sales 1 type of ... We don't need asset contract
//	// TODO: buyFungibleFromWithEth
//	// address _from, uint256 _tokenID, address _assetContract, uint256 _amountOrIndex can be removed
//	// We don't need params, know who's sender and the amount is calculated with msg.value
////	function buyFromWithETH(address _from, string _assetName, address _assetContract, uint256 _amount) public payable {
//////	    buyTokens(address(this));
//////	    require(twoKeyCampaignInventory.addFungibleAsset(_tokenID, _assetContract, _amountOrIndex));
////	    buyFromWithETH(_from, _assetName, _assetContract, _amount, CampaignType.CPA_FUNGIBLE);
////	}

}

