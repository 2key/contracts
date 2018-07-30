pragma solidity ^0.4.24;

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

import './ComposableAssetFactory.sol';
import './TwoKeyWhitelisted.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyTypes.sol';

contract TwoKeyEscrow is ComposableAssetFactory {

    using SafeMath for uint256;

    // emit through it events for backend to listen to
    TwoKeyEventSource eventSource;


    address internal contractor;
    address internal moderator;
    address internal buyer;


    /*
     * whitelist of converters. 
     * to actually conclude the escorw positively, 
     * the converter is to be approved first through the moderator
     */
    TwoKeyWhitelisted whitelistConverter;

    // is the converter eligible for participation in conversion
    modifier isWhiteListedConverter() {
        require(whitelistConverter.isWhitelisted(buyer));
        _;
    }

    modifier onlyContractorOrModerator() {
        require(msg.sender == contractor || msg.sender == moderator);
        _;
    }

    constructor(
        TwoKeyEventSource _eventSource, 
        address _contractor, 
        address _moderator, 
        address _buyer, 
        uint256 _start, 
        uint256 _duration, 
        TwoKeyWhitelisted _whitelistConverter
        ) 
        ComposableAssetFactory(_start, _duration) public {
        eventSource = _eventSource;
        contractor = _contractor;
        moderator = _moderator;
        buyer = _buyer;
        whitelistConverter = _whitelistConverter;
    }



    /**
     * transferNonFungibleChildTwoKeyToken 
     * @param  _tokenID  sku of asset
     * @param  _childContract erc721 representing the asset class
     * @param  _childTokenID  unique index of asset
     * 
     * transfer the asset to the buyer,
     */
    function transferNonFungibleChildTwoKeyToken(
        uint256 _tokenID,
        address _childContract,
        uint256 _childTokenID) isWhiteListedConverter onlyContractorOrModerator public {
        require(super.transferNonFungibleChild(buyer, _tokenID, _childContract, _childTokenID));                 
    }

    /**
     * transferFungibleChildTwoKeyToken 
     * @param  _tokenID  sku of asset
     * @param  _childContract erc20 representing the asset class
     * @param  _amount amount of asset bought
     * 
     * transfer the asset to the buyer,
     */
    function transferFungibleChildTwoKeyToken(
        uint256 _tokenID,
        address _childContract,
        uint256 _amount) isWhiteListedConverter onlyContractorOrModerator public { 
        require(super.transferFungibleChild(buyer, _tokenID, _childContract, _amount));                  
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
        uint256 _childTokenID) onlyContractorOrModerator public {
        super.transferNonFungibleChild(owner, _tokenID, _childContract, _childTokenID);

        eventSource.cancelled(address(this), buyer, _tokenID, _childContract, _childTokenID, CampaignType.NonFungible);
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
        uint256 _amount) onlyContractorOrModerator public {
        super.transferFungibleChild(owner, _tokenID, _childContract, _amount);
        
        eventSource.cancelled(address(this), buyer, _tokenID, _childContract, _amount, CampaignType.Fungible);
    }

}