pragma solidity ^0.4.24; 

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

import './ERC20full.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyWhitelisted.sol';
import './ComposableAssetFactory.sol';
import './TwoKeyEscrow.sol';
import './TwoKeyTypes.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyARC.sol';

contract TwoKeyCampaign is TwoKeyARC, ComposableAssetFactory {

	using SafeMath for uint256;

	struct Conversion {
		address from;
		uint256 payout;
		address buyer;	
		bool isFulfilled;
		bool isCancelled;
		uint256 tokenID;
		address childContract;
		uint256 indexOrAmount;
		CampaignType campaignType;
	}

	mapping (address => Conversion) public conversions;

	
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
		uint256 _maxPi) TwoKeyARC(_eventSource, _contractor) ComposableAssetFactory(_start, _duration) StandardToken() public {

		require(_eventSource != address(0));
		require(_economy != address(0));
		require(_whitelistInfluencer != address(0));
		require(_whitelistConverter != address(0));
		require(_rate > 0);
		require(_maxPi > 0);

		adminAddRole(msg.sender, ROLE_CONTROLLER);

		balances[msg.sender] = totalSupply_;

		economy = _economy;
		whitelistInfluencer = _whitelistInfluencer;
		whitelistConverter = _whitelistConverter;		
		
		contractor = _contractor;
		moderator = _moderator;

		expiryConversion = _expiryConversion;
		escrowPrecentage = _escrowPrecentage;

		rate = _rate;

		// in general max_pi is dynamic and is computed by the incentive model 
	    // per conversion
	    // there should be a discount - but not for now

	    maxPi = _maxPi;

		
		eventSource.created(address(this), owner);

	}

    /*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillFungibleTwoKeyToken(address _from, uint256 _tokenID, address _childContract, uint256 _amount) isOngoing internal {	
		require(_amount > 0 && prices[_tokenID][_childContract] > 0);
		uint256 payout = prices[_tokenID][_childContract].mul(_amount).mul(rate);
		require(economy.transferFrom(msg.sender, this, payout));	
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _childContract, _amount, CampaignType.Fungible);
		// move funds
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, contractor, moderator, msg.sender, now, expiryConversion, whitelistConverter);   		
		require(
	      _childContract.call(
	        bytes4(keccak256("transfer(address,uint256)")),
	        esc,
	        _amount
	      )
	    );
		eventSource.escrow(address(this), esc, msg.sender, _tokenID, _childContract, _amount, CampaignType.Fungible);	
		conversions[address(esc)] = c;
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
		require(_index != 0 && prices[_tokenID][childToken] > 0);
		uint256 payout = prices[_tokenID][childToken].mul(rate);
		require(economy.transferFrom(msg.sender, this, payout));	
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _childContract, _index, CampaignType.NonFungible);
		// move funds
		TwoKeyEscrow esc = new TwoKeyEscrow(eventSource, contractor, moderator, msg.sender, now, expiryConversion, whitelistConverter);
		require(
	      _childContract.call(
	        bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
	        _to, _childTokenID
	      )
	    );
		eventSource.escrow(address(this), esc, msg.sender, _tokenID, _childContract, _index, CampaignType.NonFungible);
		conversions[address(esc)] = c;
	}

	/**
     * given the total payout, calculates the moderator fee
     * @param  _payout total payout for escrow 
     * @return moderator fee
     */
    function calculateModeratorFee(uint256 _payout) internal view returns (uint256)  {
        if (escrowPrecentage > 0) { // send the fee to moderator
            uint256 fee = _payout.mul(escrowPrecentage).div(100);
            return fee;
        }  
        return 0;      
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
		require(c.from != address(0));
		require(!c.isFulfilled && !c.isCancelled);
		uint256 fee = calculateModeratorFee(c.payout);
        require(economy.transfer(moderator, fee.mul(rate))); 
        uint256 payout = c.payout;
        uint256 maxReward = maxPi.mul(payout).div(100);
        
        // transfer payout - fee - rewards to seller
        require(economy.transfer(contractor, (payout.sub(fee).sub(maxReward)).mul(rate)));
        
        transferRewardsTwoKeyToken(c.from, maxReward.mul(rate));
        eventSource.fulfilled(address(this), c.buyer, c.tokenID, c.childContract, c.indexOrAmount, c.campaignType);
	}

	function escrowExpired(TwoKeyEscrow _esc) onlyOwner public {
       Conversion memory c = conversions[address(_esc)];
       require(!c.isFulfilled);
       c.isCancelled = true;
       conversions[address(_esc)] = c;
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

}

