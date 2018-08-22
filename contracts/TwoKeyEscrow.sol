pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './TimedComposableAssetFactory.sol';
import './TwoKeyWhitelisted.sol';
import './TwoKeyCampaign.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyEventSource.sol';

contract TwoKeyEscrow is TimedComposableAssetFactory {

    using SafeMath for uint256;

    // emit through it events for backend to listen to
    TwoKeyEventSource eventSource;

    // influencer from which referral was received
    address internal from;

    // payout to converter 
    // from which moderator fee and rewards will be paid
    uint256 internal payout;

    // 2key token 
    TwoKeyEconomy internal economy;

    // campaign generating this escrow
    TwoKeyCampaign internal campaign;

    address internal buyer;
    address internal seller;
    address internal moderator;

    // precentage of moderator fee for escrow from payout 
    uint256 internal escrowPrecentage;

    // rate of conversion from TwoKey to ETH
    uint256 internal rate;

    // maximum precentage of all rewards out of payout for asset
    uint256 internal maxPi;

    /*
     * whitelist of converters. 
     * to actually conclude the escorw positively, 
     * the converter is to be approved first through the moderator
     */
    TwoKeyWhitelisted whitelistConverter;

    // is the converter eligible for participation in conversion
    modifier isWhiteListedConverter() {
        require(whitelistConverter.isWhitelisted(msg.sender));
        _;
    }

    constructor(TwoKeyEventSource _eventSource, address _from, TwoKeyEconomy _economy, uint256 _payout, TwoKeyCampaign _campaign, address _buyer, address _seller, address _moderator, uint256 _escrowPrecentage, uint256 _start, uint256 _duration, TwoKeyWhitelisted _whitelistConverter, uint256 _rate, uint256 _maxPi) TimedComposableAssetFactory(_start, _duration) public {
        eventSource = _eventSource;
        from = _from;
        economy =_economy;
        campaign = _campaign;
        buyer = _buyer;
        seller = _seller;
        moderator = _moderator;
        escrowPrecentage = _escrowPrecentage;
        rate = _rate;
        maxPi = _maxPi;
        payout = _payout;
        whitelistConverter = _whitelistConverter;
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _balance total payout for escrow 
     * @return moderator fee
     */
    function calculateModeratorFee(uint256 _balance) internal view returns (uint256)  {
        if (escrowPrecentage > 0) { // send the fee to moderator
            uint256 fee = _balance.mul(escrowPrecentage).div(100);
            return fee;
        }  
        return 0;      
    }

    /**
     * transferNonFungibleChildTwoKeyToken 
     * @param  _tokenID  sku of asset
     * @param  _childContract erc721 representing the asset class
     * @param  _childTokenID  unique index of asset
     * 
     * calculates moderetor fee, pays the moderator, 
     * transfer the asset to the buyer,
     * computes total reward
     * transfer payout to buyer, deducting the fee and the total reward
     * asks the campaign to distribute rewards to influencers
     */
    function transferNonFungibleChildTwoKeyToken(
        uint256 _tokenID,
        address _childContract,
        uint256 _childTokenID) onlyOwner isWhiteListedConverter public {
        require(rate > 0);
        uint256 fee = calculateModeratorFee(token.balanceOf(this));
        require(token.transfer(moderator, fee.mul(rate)));
        require(super.transferNonFungibleChild(buyer, _tokenID, _childContract, _childTokenID));         
       
        uint256 maxReward = maxPi.mul(payout).div(100);

        // transfer payout - fee - rewards to seller
        require(token.transfer(seller, ourBalance.sub(fee).sub(maxReward).mul(rate)));
 
        // transfer rewards from escrow to influencers
        campaign.transferRewardsTwoKeyToken(from, maxReward.mul(rate));
        uint256 ourBalance = token.balanceOf(this);
        eventSource.fulfilled(campaign, buyer, _tokenID, _childContract, _childTokenID);     
    }

    /**
     * transferFungibleChildTwoKeyToken 
     * @param  _tokenID  sku of asset
     * @param  _childContract erc20 representing the asset class
     * @param  _amount amount of asset bought
     * 
     * calculates moderetor fee, pays the moderator, 
     * transfer the asset to the buyer,
     * computes total reward
     * transfer payout to buyer, deducting the fee and the total reward
     * asks the campaign to distribute rewards to influencers
     */
    function transferFungibleChildTwoKeyToken(
        uint256 _tokenID,
        address _childContract,
        uint256 _amount) onlyOwner isWhiteListedConverter public { 
        require(rate > 0);   
        uint256 fee = calculateModeratorFee(token.balanceOf(this));
        require(token.transferFrom(this, moderator, fee.mul(rate)));
        require(super.transferFungibleChild(buyer, _tokenID, _childContract, _amount));         
        
        uint256 maxReward = maxPi.mul(payout).div(100);

        // transfer payout - fee - rewards to seller
        require(token.transfer(seller, (payout.sub(fee).sub(maxReward)).mul(rate)));
        
        campaign.transferRewardsTwoKeyToken(from, maxReward.mul(rate));
        eventSource.fulfilled(campaign, buyer, _tokenID, _childContract, _amount);        
    }

    /**
     * cancelNonFungibleChildTwoKey 
     * cancels the purchase buy transfering the assets back to the campaign
     * and refunding the buyer
     * @param  _tokenID  sku of asset
     * @param  _childContract erc721 representing the asset class
     * @param  _childTokenID unique index of asset
     * 
     */
    function cancelNonFungibleChildTwoKey(
        uint256 _tokenID,
        address _childContract,
        uint256 _childTokenID) onlyOwner public {
        require(rate > 0);
        super.transferNonFungibleChild(campaign, _tokenID, _childContract, _childTokenID);
        token.transfer(buyer, payout.mul(rate));
        eventSource.cancelled(campaign, buyer, _tokenID, _childContract, _childTokenID);
    }

    /**
     * cancelFungibleChildTwoKey 
     * cancels the purchase buy transfering the assets back to the campaign
     * and refunding the buyer
     * @param  _tokenID  sku of asset
     * @param  _childContract erc20 representing the asset class
     * @param  _amount amount of asset bought
     * 
     */
    function cancelFungibleChildTwoKey(
        uint256 _tokenID,
        address _childContract,
        uint256 _amount) onlyOwner public {
        require(rate > 0);
        super.transferFungibleChild(campaign, _tokenID, _childContract, _amount);
        token.transfer(buyer, payout.mul(rate));
        eventSource.cancelled(campaign, buyer, _tokenID, _childContract, _amount);
    }

}