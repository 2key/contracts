pragma solidity ^0.4.24; 

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

import './ERC20full.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyWhitelisted.sol';
import './ComposableAssetFactory.sol';
import './TwoKeyTypes.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyARC.sol';

contract TwoKeyCampaign is TwoKeyARC, ComposableAssetFactory, TwoKeyTypes {

	using SafeMath for uint256;

	struct Conversion {
		address from;
		uint256 payout;
		address converter;	
		bool isFulfilled;
		bool isCancelled;
		uint256 tokenID;
		address assetContract;
		uint256 indexOrAmount;
		CampaignType campaignType;
		uint256 openingTime;
		uint256 closingTime;
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

	// is the converter eligible for participation in conversion
    modifier isWhitelistedConverter() {
        require(whitelistConverter.isWhitelisted(msg.sender));
        _;
    }

    modifier didConverterConvert() {
        Conversion memory c = conversions[msg.sender];
    	require(c.tokenID != 0);
    	require(!c.isFulfilled && !c.isCancelled);
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
		
		uint256 _openingTime,
		uint256 _closingTime,
		uint256 _expiryConversion, 
		uint256 _escrowPrecentage,
		uint256 _rate,
		uint256 _maxPi) TwoKeyARC(_eventSource, _contractor) ComposableAssetFactory(_openingTime, _closingTime) StandardToken() public {

		require(_eventSource != address(0));
		require(_economy != address(0));
		require(_whitelistInfluencer != address(0));
		require(_whitelistConverter != address(0));
		require(_rate > 0);
		require(_maxPi > 0);

		adminAddRole(msg.sender, ROLE_CONTROLLER);
		adminAddRole(_contractor, ROLE_CONTROLLER);
		adminAddRole(_moderator, ROLE_CONTROLLER);

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

		
		// eventSource.created(address(this), contractor);

	}

    /*  
	    fulfills a fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillFungibleTwoKeyToken(
		address _from, 
		uint256 _tokenID, 
		address _assetContract, 
		uint256 _amount) isOngoing internal {	
		require(_amount > 0 && prices[_tokenID][_assetContract] > 0);
		uint256 payout = prices[_tokenID][_assetContract].mul(_amount).mul(rate);
		require(economy.transferFrom(msg.sender, this, payout));	
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _assetContract, _amount, CampaignType.Fungible, now, now + expiryConversion * 1 minutes);
		// move funds
		assets[_tokenID][_assetContract] -= _amount;
		eventSource.escrow(address(this), msg.sender, _tokenID, _assetContract, _amount, CampaignType.Fungible);	
		conversions[msg.sender] = c;
	}


    /*  
	    fulfills a non fungible asset purchase
	    creates the escrow for a fungible asset
	    computes the payout 
	    transfers to the escrow the asset purchased
    */ 
	function fulfillNonFungibleTwoKeyToken(address _from, uint256 _tokenID, address _assetContract, uint256 _index) isOngoing internal {	
		address assetToken = address(
	      keccak256(abi.encodePacked(_assetContract, _index))
	    );
		require(_index != 0 && prices[_tokenID][assetToken] > 0);
		uint256 payout = prices[_tokenID][assetToken].mul(rate);
		require(economy.transferFrom(msg.sender, this, payout));	
		Conversion memory c = Conversion(_from, payout, msg.sender, false, false, _tokenID, _assetContract, _index, CampaignType.NonFungible, now, now + expiryConversion * 1 minutes);
		// move funds
		assets[_tokenID][assetToken] = 0;
		eventSource.escrow(address(this), msg.sender, _tokenID, _assetContract, _index, CampaignType.NonFungible);
		conversions[msg.sender] = c;
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
     * transferAssetTwoKeyToken 
     * @param  _tokenID  sku of asset
     * @param  _assetContract erc721 representing the asset class
     * @param  _assetTokenIDOrAmount  unique index of asset or amount of asset
     * @param  _type Fungible or NonFungible
     * 
     * transfer the asset to the converter,
     */
    function transferAssetTwoKeyToken(
        uint256 _tokenID,
        address _assetContract,
        uint256 _assetTokenIDOrAmount,
        CampaignType _type) isWhitelistedConverter didConverterConvert public {    
        actuallyFulfilledTwoKeyToken();  
        if (_type == CampaignType.NonFungible) {
			require(transferNonFungibleAsset(msg.sender, _tokenID, _assetContract, _assetTokenIDOrAmount));  
        } else if (_type == CampaignType.Fungible) {
			require(transferFungibleAsset(msg.sender, _tokenID, _assetContract, _assetTokenIDOrAmount));  
        }
                    
    }

    function cancelledEscrow(
    	address _converter,
        uint256 _tokenID,
        address _assetContract,
        uint256 _assetTokenIDOrAmount,
        CampaignType _type) internal {
        Conversion memory c = conversions[_converter];
        c.isCancelled = true;
        conversions[_converter] = c;
        if (_type == CampaignType.NonFungible) {
	        address assetToken = address(
		      keccak256(abi.encodePacked(_assetContract, _assetTokenIDOrAmount))
		    );
	        assets[_tokenID][assetToken] = 1;          	
        } else if (_type == CampaignType.Fungible) {
	        assets[_tokenID][_assetContract] += _assetTokenIDOrAmount;  
        }

        require(economy.transfer(_converter, (c.payout).mul(rate)));	
    }


    /**
     * cancelAssetTwoKey 
     * cancels the purchase buy transfering the assets back to the campaign
     * and refunding the converter
     * @param  _tokenID  sku of asset
     * @param  _assetContract erc721 representing the asset class
     * @param  _assetTokenIDOrAmount unique index of asset or amount of asset
     * @param  _type NonFungible or Fungible
     * 
     */
    function cancelAssetTwoKey(
        address _converter,
        uint256 _tokenID,
        address _assetContract,
        uint256 _assetTokenIDOrAmount,
        CampaignType _type) onlyRole(ROLE_CONTROLLER) public returns (bool) {
    	Conversion memory c = conversions[_converter];
	    require(c.tokenID != 0 && !c.isCancelled && !c.isFulfilled);
	    if (_type == CampaignType.NonFungible) {
	    	cancelledEscrow(_converter, _tokenID, _assetContract, _assetTokenIDOrAmount, CampaignType.NonFungible);
	        eventSource.cancelled(address(this), _converter, _tokenID, _assetContract, _assetTokenIDOrAmount, CampaignType.NonFungible);
	    } else if (_type == CampaignType.Fungible) {
	    	cancelledEscrow(_converter, _tokenID, _assetContract, _assetTokenIDOrAmount, CampaignType.Fungible);
        	eventSource.cancelled(address(this), _converter, _tokenID, _assetContract, _assetTokenIDOrAmount, CampaignType.Fungible);
	    }
        return true;
    }


    function expireEscrow(
		address _converter,
		uint256 _tokenID,
		address _assetContract,
		uint256 _assetTokenIDOrAmount,
		CampaignType _type) onlyRole(ROLE_CONTROLLER) public returns (bool){   
	    Conversion memory c = conversions[_converter];
	    require(c.tokenID != 0 && !c.isCancelled && !c.isFulfilled);
    	require(now > c.closingTime);
		cancelledEscrow(_converter, _tokenID, _assetContract, _assetTokenIDOrAmount, _type);
		emit Expired(address(this));
		return true;
	}


    /**
     * calculates moderetor fee, pays the moderator, 
     * computes total reward
     * transfer payout to contractor, deducting the fee and the total reward
     * asks the campaign to distribute rewards to influencers
     */

	function actuallyFulfilledTwoKeyToken() internal {
		Conversion memory c = conversions[msg.sender];
        c.isFulfilled = true; 
        conversions[msg.sender] = c;
		uint256 fee = calculateModeratorFee(c.payout);
        require(economy.transfer(moderator, fee.mul(rate))); 
        uint256 payout = c.payout;
        uint256 maxReward = maxPi.mul(payout).div(100);
        
        // transfer payout - fee - rewards to seller
        require(economy.transfer(contractor, (payout.sub(fee).sub(maxReward)).mul(rate)));
        
        transferRewardsTwoKeyToken(c.from, maxReward.mul(rate));
        eventSource.fulfilled(address(this), c.converter, c.tokenID, c.assetContract, c.indexOrAmount, c.campaignType);
	}

	// set price for fungible asset held by the campaign
	function setPriceFungible(uint256 _tokenID, address _assetContract, uint256 _pricePerUnit) onlyRole(ROLE_CONTROLLER) public {
		prices[_tokenID][_assetContract] = _pricePerUnit;
	}

	// set price for a non fungible asset held by the campaign
	function setPriceNonFungible(uint256 _tokenID, address _assetContract, uint256 _index, uint256 _pricePerUnit) onlyRole(ROLE_CONTROLLER) public {
		address assetToken = address(
	      keccak256(abi.encodePacked(_assetContract, _index))
	    );
		prices[_tokenID][assetToken] = _pricePerUnit;
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
  	 * _assetContract - erc20 (fungible) or erc721 (non fungible) which represents the class of the asset
  	 * _amountOrIndex - for erc20 amount in asset class, for erc21 index within asset class
  	 */
	function buyFromWithTwoKey(
		address _from, 
		uint256 _tokenID, 
		address _assetContract, 
		uint256 _amountOrIndex, 
		CampaignType _campaignType) public payable {
		if (_campaignType == CampaignType.Fungible) {
			fulfillFungibleTwoKeyToken(_from, _tokenID, _assetContract, _amountOrIndex);
		} else if (_campaignType == CampaignType.NonFungible) {
			fulfillNonFungibleTwoKeyToken(_from, _tokenID, _assetContract, _amountOrIndex);
		} 
	}

}

