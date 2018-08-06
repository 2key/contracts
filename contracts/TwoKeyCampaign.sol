pragma solidity ^0.4.24; 

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './ERC20full.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyWhitelisted.sol';
import './TimedComposableAssetFactory.sol';
import './TwoKeyEscrow.sol';
import './TwoKeyTypes.sol';
import './TwoKeyEventSource.sol';

contract TwoKeyCampaign is StandardToken, TimedComposableAssetFactory {

	using SafeMath for uint256;

	uint256 public quota;  // maximal ARC tokens that can be passed in transferFrom

	// referral graph, who did you receive the referral from
	mapping (address => address) public received_from;
	
	// emit through it events for backend to listen to
	TwoKeyEventSource eventSource;

	// 2key token
	TwoKeyEconomy economy;

	// whitelists will be managed by their ownership
	// they are the vehicles to convey KYC for different roles: converter, influencer, contractor
	// whitelists are outside the campaign
	// these whtelists may be shared across campaigns

	// whitelist of influencers, to which users are added after kyc
	// TODO (udi) what should I do if I dont want to manage a white list?
	TwoKeyWhitelisted whitelistInfluencer; 

	// whitelist of converters, to which users are added after kyc
	TwoKeyWhitelisted whitelistConverter;

	// prices of assets
	// TODO (udi) there should be just one token->address->price you dont need two maps
	mapping(uint256 => mapping(address => uint256)) prices; 

	// rate of conversion from TwoKey to ETH
	uint256 rate;


	address contractor;
	address moderator;

	// parameters of escrow

	// how long will hold asset in escrow
	uint256 expiryConversion;

	// precentage of payout to. be paid for moderator for escrow
	uint256 escrowPrecentage;

    // maximum precentage of all rewards out of payout for asset
    // acording to incentive model, for each campaign, 
    // we set its maximum reward which the campaign is created as a precentage of the payout for
    // an item sold in the campaign
    // this reward is spread among influencers causing in some way a conversion
    // the incentive model determines how to spread the reward
	uint256 maxPi;  

	// balance of TwoKeyToken for each influencer that they can withdraw
    mapping(address => uint256) private xbalancesTwoKey; 


 
    // is the influencer eligible for participation in campaign
	modifier isWhiteListedInfluencer() {
		require(whitelistInfluencer.isWhitelisted(msg.sender));
		_;
	}


	// if we just work with two key tokens, 
	// rate is 1, and all prices are in two key tokens
	/*
	
	 */
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
		uint256 _maxPi) TimedComposableAssetFactory(_start, _duration) public {

		super.transferOwnership(msg.sender);

		economy = _economy;

		whitelistInfluencer = _whitelistInfluencer;
		whitelistConverter = _whitelistConverter;

		eventSource = _eventSource;
		
		contractor = _contractor;
		moderator = _moderator;

		rate = _rate;

		// in general max_pi is dynamic and is computed by the incentive model 
	    // per conversion
	    // there should be a discount - but not for now

	    maxPi = _maxPi;

		expiryConversion = _expiryConversion;
		escrowPrecentage = _escrowPrecentage;

		if (eventSource != address(0)) eventSource.created(owner);

	}

	// Modified 2Key method

	  
	/**
	  * @dev transfer token for a specified address
	  * @param _to The address to transfer to.
	  * @param _value The amount to be transferred.
	  */
	function transferQuota(address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[msg.sender]);

	    // SafeMath.sub will throw if there is not enough balance.
	    balances[msg.sender] = balances[msg.sender].sub(_value);
	    balances[_to] = balances[_to].add(_value * quota);
	    totalSupply_ = totalSupply_ + _value * (quota - 1);
	    emit Transfer(msg.sender, _to, _value);
	    return true;
	  }

	/**
	   * @dev Transfer tokens from one address to another
	   * @param _from address The address which you want to send tokens from
	   * @param _to address The address which you want to transfer to
	   * @param _value uint256 the amount of tokens to be transferred
	   */	  
	function transferFromQuota(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= balances[_from]);
	    require(_value <= allowed[_from][msg.sender]);

	    balances[_from] = balances[_from].sub(_value);
	    balances[_to] = balances[_to].add(_value * quota);
	    totalSupply_ = totalSupply_ + _value * (quota - 1);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    emit Transfer(_from, _to, _value);
	    return true;
	  }

	/**
	   * @dev Transfer tokens from one address to another
	   * @param _from address The address which you want to send tokens from
	   * @param _to address The address which you want to transfer to
	   * @param _value uint256 the amount of tokens to be transferred
	   */
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(received_from[_to] == 0);
	    require(_from != address(0));
	    allowed[_from][msg.sender] = 1;
	    if (transferFromQuota(_from, _to, _value)) {
	      if (received_from[_to] == 0) {
	        // inform the 2key admin contract, once, that an influencer has joined
	        eventSource.joined(_to);
	      }
	      received_from[_to] = _from;
	      return true;
	    } else {
	      return false;
	    }
	}

	/**
	  * @dev transfer token for a specified address
	  * @param _to The address to transfer to.
	  * @param _value The amount to be transferred.
	  */
	function transfer(address _to, uint256 _value) public returns (bool) {
	    require(received_from[_to] == 0);
	    if (transferQuota(_to, _value)) {
	      if (received_from[_to] == 0) {
	        // inform the 2key admin contract, once, that an influencer has joined
	        eventSource.joined(_to);
	      }
	      received_from[_to] = msg.sender;
	      return true;
	    } else {
	      return false;
	    }
	}


  	/**
  	 * buy product with twokey token,
  	 * _from is the influencer from which you received the referral
  	 * _tokenID is the asset sku
  	 * _childContract - erc20 (fungible) or erc721 (non fungible) which represents the class of the asset
  	 * _amountOrIndex - for erc20 amount in asset class, for erc21 index within asset class
  	 */
	function buyFromWithTwoKey(address _from, uint256 _tokenID, address _childContract, uint256 _amountOrIndex) public payable {
	    buyProductTwoKey(_from, _tokenID, _childContract, _amountOrIndex); 
	}

	// internal function that splits the treatment for fungible or non fungible
	function buyProductTwoKey(address _from, uint256 _tokenID, address _childContract, uint256 _amountOrIndex) internal {
		CampaignType campaignType = getType(_tokenID);
		if (campaignType == CampaignType.Fungible) {
			fulfillFungibleTwoKeyToken(_from, _tokenID, _childContract, _amountOrIndex);
		} else if (campaignType == CampaignType.NonFungible) {
			fulfillNonFungibleTwoKeyToken(_from, _tokenID, _childContract, _amountOrIndex);
		} 
	}

    /*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillFungibleTwoKeyToken(address _from, uint256 _tokenID, address _childContract, uint256 _amount) isOngoing internal {	
		require(_amount > 0 && prices[_tokenID][_childContract] > 0 && rate > 0);
		uint256 payout = prices[_tokenID][_childContract].mul(_amount).mul(rate);
		require(economy.allowance(msg.sender, this) == payout);	
		// move funds
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, _from, economy, payout, this, msg.sender, contractor, moderator, escrowPrecentage, now, expiryConversion, whitelistConverter, rate, maxPi);   
		esc.transferOwnership(moderator);	
		require(economy.transferFrom(this, esc, payout));
		super.transferFungibleChild(esc, _tokenID, _childContract, _amount);
		// notification to moderator
		eventSource.escrow(this, esc, msg.sender, _tokenID, _childContract, _amount);
	}

    /*  
	    fulfills a non fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillNonFungibleTwoKeyToken(address _from, uint256 _tokenID, address _childContract, uint256 _index) isOngoing internal {	
		address childToken = address(
	      keccak256(abi.encodePacked(_childContract, _index))
	    );
		require(_index != 0 && prices[_tokenID][childToken] > 0 && rate > 0);
		uint256 payout = prices[_tokenID][childToken].mul(rate);
		require(economy.allowance(msg.sender, this) == payout);	
		// move funds
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, _from, economy, payout, this, msg.sender, contractor, moderator, escrowPrecentage, now, expiryConversion, whitelistConverter, rate, maxPi);
		esc.transferOwnership(moderator);
		require(economy.transferFrom(this, esc, payout));
		super.transferNonFungibleChild(esc, _tokenID, _childContract, _index);
		eventSource.escrow(this, esc, msg.sender, _tokenID, _childContract, _index);
	}

	// set price for fungible asset held by the campaign
	function setPriceFungible(uint256 _tokenID, address _childContract, uint256 _pricePerUnit) onlyOwner public {
		prices[_tokenID][_childContract] = _pricePerUnit;
	}

	// set price for a non fungible asset held by the campaign
	function setPriceNonFungible(uint256 _tokenID, address _childContract, uint256 _index, uint256 _pricePerUnit) onlyOwner public {
		address childToken = address(
	      keccak256(abi.encodePacked(_childContract, _index))
	    );
		prices[_tokenID][childToken] = _pricePerUnit;
	}

	// an influencer that wishes to cash an _amount of 2key from the campaign
	function redeemTwoKeyToken(uint256 _amount) public {
        require(xbalancesTwoKey[msg.sender] >= _amount && _amount > 0);
        xbalancesTwoKey[msg.sender] = xbalancesTwoKey[msg.sender].sub(_amount);
        economy.transferFrom(this, msg.sender, _amount);
    }

    // incentive model
    // no reputation model really
    // compute the last referral chain, _from is the last influencer before the converter, and _maxReward is the total rewarded
    // to all influencers
    function transferRewardsTwoKeyToken(address _from, uint256 _maxReward) public { 

		require(_from != address(0));
	    address _to = msg.sender;

	    // if you dont have ARCs then first take them (join) from _from
	    if (this.balanceOf(_to) == 0) {
	      transferFrom(_from, _to, 1);
	    }


	    // compute last referral chain
	   
	    uint256 influencersCount;
	    address influencer = msg.sender;
	    while (true) {
	        influencer = received_from[influencer];
	        if (influencer == owner) {
	            break;
	        }
	        influencersCount++;
	    }
        
        uint256 rewardPerInfluencer = _maxReward.div(influencersCount);
        influencer = msg.sender;
        for(uint256 i = 0; i < influencersCount; i++) {
        	influencer = received_from[influencer];
            xbalancesTwoKey[influencer] = xbalancesTwoKey[influencer].add(rewardPerInfluencer);
            eventSource.rewarded(address(this), influencer, rewardPerInfluencer);
        }

    }

}

