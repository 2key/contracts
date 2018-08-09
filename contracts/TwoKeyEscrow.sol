pragma solidity ^0.4.24;

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

import './ComposableAssetFactory.sol';
import './TwoKeyWhitelisted.sol';
import './TwoKeyEventSource.sol';
import './TwoKeyTypes.sol';

contract TwoKeyEscrow is ComposableAssetFactory, TwoKeyTypes {

    using SafeMath for uint256;

    // emit through it events for backend to listen to
    TwoKeyEventSource eventSource;

    address internal buyer;
    
    bool internal buyerWhitelisted;


    /*
     * whitelist of converters. 
     * to actually conclude the escorw positively, 
     * the converter is to be approved first through the moderator
     */
    TwoKeyWhitelisted whitelistConverter;

    // is the converter eligible for participation in conversion
    modifier onlyApprovedConverter() {
        // require(whitelistConverter.isWhitelisted(buyer));
        require(buyerWhitelisted);
        _;
    }

    constructor(
        TwoKeyEventSource _eventSource, 
        address _contractor, 
        address _moderator, 
        address _buyer, 
        uint256 _openingTime, 
        uint256 _closingTime, 
        TwoKeyWhitelisted _whitelistConverter
        ) 
        ComposableAssetFactory(_openingTime, _closingTime) public {

        eventSource = _eventSource;
        adminAddRole(_contractor, ROLE_CONTROLLER);
        adminAddRole(_moderator, ROLE_CONTROLLER);
        buyer = _buyer;
        whitelistConverter = _whitelistConverter;
     }

    
    /**
     * 
     * 
     */
    function approveBuyer(
        ) onlyRole(ROLE_CONTROLLER) {
        
        buyerWhitelisted = true;
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
        uint256 _childTokenID) onlyApprovedConverter public {
        require(transferNonFungibleChild(buyer, _tokenID, _childContract, _childTokenID));                 
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
        uint256 _amount) onlyApprovedConverter public { 
        require(transferFungibleChild(buyer, _tokenID, _childContract, _amount));                  
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
        address _to,
        uint256 _tokenID,
        address _childContract,
        uint256 _childTokenID) onlyRole(ROLE_CONTROLLER) public {
        moveNonFungibleChild(_to, _tokenID, _childContract, _childTokenID);
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
        address _to,
        uint256 _tokenID,
        address _childContract,
        uint256 _amount) onlyRole(ROLE_CONTROLLER) public {
        moveFungibleChild(_to, _tokenID, _childContract, _amount);
        eventSource.cancelled(address(this), buyer, _tokenID, _childContract, _amount, CampaignType.Fungible);
    }

}