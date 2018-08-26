pragma solidity ^0.4.24;

// based on https://medium.com/coinmonks/introducing-crypto-composables-ee5701fde217

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

import './RBACWithAdmin.sol';

contract ComposableAssetFactory is RBACWithAdmin { 

  event Expired(address indexed _contract);

  using SafeMath for uint256;
  

  uint256 private openingTime;
  uint256 private closingTime;

//  modifier isOngoing() {
//    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
//    _;
//  }
//
//  modifier isClosed() {
//    require(now > closingTime);
//    _;
//  }


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


  /// @notice Constructor for factory
  /// @dev RBACWithAdmin() is contract we've inherited and it's constructor will set msg.sender to be an admin
  /// @param _openingTime is opening time
  /// @param _closingTime is closing time
  constructor(uint256 _openingTime, uint256 _closingTime) RBACWithAdmin() public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);    
    openingTime = _openingTime;
    closingTime = _closingTime;
  }


  // add erc20 asset amount to the store, which adds an amount of that erc20 to our catalogue
  function addFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _amount) public returns (bool) {
    require(isOnGoing() == true);
    require(
      _assetContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        address(this),
        _amount
      )
    );

    // set as asset
    assets[_tokenID][_assetContract] += _amount;

    return true;
  }

  // add erc721 asset to the store, which adds a particular unique item from that erc721 to our catalogue
  function addNonFungibleAsset(uint256 _tokenID, address _assetContract, uint256 _index) public returns (bool) {
    require(isOnGoing() == true);
    require(
      _assetContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        _index
      )
    );

    // set as asset
    address assetToken = address(
      keccak256(abi.encodePacked(_assetContract, _index))
    );
    assets[_tokenID][assetToken] = 1;

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
//    require(assets[_tokenID][assetToken] == 1);
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
    uint256 _amount) public returns (bool) {
    return moveFungibleAsset(_to, _tokenID, _assetContract, _amount);
  }

  // transfer a unique item from a erc721 in our catalogue to someone
  // public - need to be callable only by two key campaign
  function transferNonFungibleAsset(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _assetTokenID) onlyRole(ROLE_CONTROLLER) public returns (bool) {
    require(isOnGoing() == true);
    return moveNonFungibleAsset(_to, _tokenID, _assetContract, _assetTokenID);
  }

  function expireFungible(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _amount) onlyRole(ROLE_CONTROLLER) public returns (bool) {
    require(isClosed() == true);
    moveFungibleAsset(_to, _tokenID, _assetContract, _amount);
    emit Expired(address(this));
    return true;
  }

  function expireNonFungible(
    address _to,
    uint256 _tokenID,
    address _assetContract,
    uint256 _assetTokenID) onlyRole(ROLE_CONTROLLER) public returns (bool){
    require(isClosed() == true);
    moveNonFungibleAsset(_to, _tokenID, _assetContract, _assetTokenID);
    emit Expired(address(this));
    return true;
  }

  /// @notice Since we don't any more inherit this contract, we can access to it's variables and modify them only with functions
  /// @notice Removes specific amount of assets
  /// @dev need to setup some kind of validation that only TwoKeyCampaign contract can call this
  /// @param _tokenID is id of token
  /// @param _assetContract is address of asset contract
  /// @param _amount is the actual amount
  function remAssets(uint _tokenID, address _assetContract, uint _amount) public {
      assets[_tokenID][_assetContract] -= _amount;
  }

  /// @notice Since we don't any more inherit this contract, we can access to it's variables and modify them only with functions
  /// @notice Adds specific amount of assets
  /// @dev need to setup some kind of validation that only TwoKeyCampaign contract can call this
  /// @param _tokenID is id of token
  /// @param _assetContract is address of asset contract
  /// @param _amount is the actual amount
  function addAssets(uint _tokenID, address _assetContract, uint _amount) public {
    assets[_tokenID][_assetContract] += _amount;
  }
  /// @notice Since we don't any more inherit this contract, we can access to it's variables and modify them only with functions
  /// @notice Sets amount of assets to 0
  /// @dev need to setup some kind of validation that only TwoKeyCampaign contract can call this
  /// @param _tokenID is id of token
  /// @param _assetContract is address of asset contract
  function setAssetsToZero(uint _tokenID, address _assetContract) public {
    assets[_tokenID][_assetContract] = 0;
  }
  /// @notice Since we don't any more inherit this contract, we can access to it's variables and modify them only with functions
  /// @notice Sets amount of assets to 1
  /// @dev need to setup some kind of validation that only TwoKeyCampaign contract can call this
  /// @param _tokenID is id of token
  /// @param _assetContract is address of asset contract
  function setAssetsToOne(uint _tokenID, address _assetContract) public {
    assets[_tokenID][_assetContract] = 1;
  }



  /// Since we can't use modifiers anymore here, we'll use functions and call them in other contracts / implement modifiers there
  /// @notice Function to replace old modifier isOngoing - checks if current time is between opening and closing time
  /// @dev Because TwoKeyCampaign doesn't inherit anymore this contract, it doesn't have access to it's modifiers
  /// @return - if require pass will return true, otherwise it will revert trnx
  function isOnGoing() public view returns (bool) {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    return true;
  }


  /// Since we can't use modifiers anymore here, we'll use functions and call them in other contracts / implement modifiers there
  /// @notice Function to replace old modifier isClosed - checks if current time is greater than closingTime
  /// @dev Because TwoKeyCampaign doesn't inherit anymore this contract, it doesn't have access to it's modifiers
  /// @return - if require pass, will return true, otherwise it will revert trnx
  function isClosed() public view returns (bool) {
    require(block.timestamp > closingTime);
    return true;
  }

}
