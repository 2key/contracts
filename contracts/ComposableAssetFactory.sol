pragma solidity ^0.4.24;

// based on https://medium.com/coinmonks/introducing-crypto-composables-ee5701fde217

import './openzeppelin-solidity/contracts/math/SafeMath.sol';

import './RBACWithAdmin.sol';

contract ComposableAssetFactory is RBACWithAdmin { 

  event Expired(address indexed _contract);

  using SafeMath for uint256;
  

  uint256 private openingTime;
  uint256 private closingTime;

  modifier isOngoing() {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  modifier isClosed() {
    require(now > closingTime);
    _;
  }


  /*
  
    The contract acts as a store. The assets data structure is the catalogue of the store.
    
    Each asset is identified by a uint256 tokenID that acts as a SKU (shop keeping unit)

    This SKU is set by the owner and is unique only with this particular contract
    
      mapping(uint256 => ...)

    maps a tokenID to the asset
    Such a tokenID identifies one of:

    1. ERC20 : which is represented by an entry mapping(address => uint256)
    which maps the ERC20 contract to the amount tokens we have
    2. ERC721: which is represented by an entry mapping(address => uint256)
    where the address is a hash of the concatenation of the ERC721 contract address and the unique token within that contract, and 
    the uint256 value is 1 or 0

  */


  // TODO (udi) I think it she mapping(uint256 => address) and not mapping(uint256 => mapping(address => uint256))
  // the uint256 is SKU and the address is of ERC20 or ERC721 there is just one address per SKU so we dont need more than one.
  //    You can the balanceOf method (both in ERC20 and ERC721) instead of using the last uint256 or counting how many entries you have
  //    in mapping(address => uint256). From reading the interface of ERC721 it looks like it is not very important to
  //    remeber which NFT you used. If you really want you can do a mapping from SKU to a struct. the first item in the
  //    struct is the address and the second item is a map of all the NFT the campaign owns mapping(uint256 => bool)
  //    but this is not elegant because this mapping is only needed for ERC721 and not for ERC20 so you should really put
  //    it in a subclass. Anyway I dont think we need ETC721 and even if we support ERC721 we dont need to keep track of which tokenID (NFT)
  //    is used.
  //
  mapping(uint256 => mapping(address => uint256)) assets;

  constructor(uint256 _openingTime, uint256 _closingTime) RBACWithAdmin() public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);    
    openingTime = _openingTime;
    closingTime = _closingTime;
  }


  // remove isOngoing modifier - there is the error, need to find out.
  // add erc20 asset amount to the store, which adds an amount of that erc20 to our catalogue
  function addFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _amount) isOngoing public returns (bool) {
    // set as asset
    assets[_tokenID][_assetContract] += _amount;

    require(
      _assetContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        address(this),
        _amount
      )
    );
    return true;
  }

  // add erc721 asset to the store, which adds a particular unique item from that erc721 to our catalogue
  function addNonFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _index) isOngoing public returns (bool) {
    address assetToken = address(
      keccak256(abi.encodePacked(_assetContract, _index))
    );

    // set as asset
    assets[_tokenID][assetToken] = 1;
    require(
      _assetContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        _index
      )
    );
    return true;
  }
  // commented line where transaction reverted.
  // move an amount of erc20 from our catalogue to someone
  function moveFungibleAsset(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _amount) internal returns (bool) {
//    require(assets[_tokenID][_assetContract] >= _amount);
    require(
      _assetContract.call(
        bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
        _to, _amount
      )
    );

    assets[_tokenID][_assetContract] -= _amount;
    return true;
  }

  // transfer a unique item from a erc721 in our catalogue to someone
  function moveNonFungibleAsset(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _assetTokenID) internal returns (bool) {
    address assetToken = address(
      keccak256(abi.encodePacked(_assetContract, _assetTokenID))
    );
    require(assets[_tokenID][assetToken] == 1);
    require(
      _assetContract.call(
        bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
        _to, _assetTokenID
      )
    );

    assets[_tokenID][assetToken] = 0;
    return true;
  }

  // transfer an amount of erc20 from our catalogue to someone
  // If transferFungibleAsset is internal that means it can't be called from out of the contract - set it to public
  // onlyRole(ROLE_CONTROLLER) modifier also doesn't work, need to check it.
  function transferFungibleAsset(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _amount)  public returns (bool) {
    return moveFungibleAsset(_to, _tokenID, _assetContract, _amount);
  }

  // transfer a unique item from a erc721 in our catalogue to someone
  function transferNonFungibleAsset(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _assetTokenID) isOngoing onlyRole(ROLE_CONTROLLER) internal returns (bool) {
    return moveNonFungibleAsset(_to, _tokenID, _assetContract, _assetTokenID);
  }

  function expireFungible(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _amount) onlyRole(ROLE_CONTROLLER) isClosed public returns (bool) {
    moveFungibleAsset(_to, _tokenID, _assetContract, _amount);
    emit Expired(address(this));
    return true;
  }

  function expireNonFungible(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _assetTokenID) onlyRole(ROLE_CONTROLLER) isClosed public returns (bool){   
    moveNonFungibleAsset(_to, _tokenID, _assetContract, _assetTokenID);
    emit Expired(address(this));
    return true;
  }

}
