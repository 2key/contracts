pragma solidity ^0.4.24;

// based on https://medium.com/coinmonks/introducing-crypto-composables-ee5701fde217

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

import './RBACWithAdmin.sol';

contract ComposableAssetFactory is RBACWithAdmin { 



  event Expired(address indexed _contract);

  using SafeMath for uint256;
  

  uint256 private openingTime;
  uint256 private closingTime;

  modifier isOngoing() {
    require(now >= openingTime && now <= closingTime);
    _;
  }

  modifier isClosed() {
    require(now > closingTime);
    _;
  }


  /*
  
    The contract acts as a store. The children data structure is the catalogue of the store.
    
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
  mapping(uint256 => mapping(address => uint256)) children;

  constructor(uint256 _openingTime, uint256 _closingTime) RBACWithAdmin() public {
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  
  // add erc20 asset amount to the store, which adds an amount of that erc20 to our catalogue
  function addFungibleChild(uint256 _tokenID, address _childContract, uint256 _amount) isOngoing public returns (bool) {
    require(
      _childContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        address(this),
        _amount
      )
    );

    // set as child
    children[_tokenID][_childContract] += _amount;
    return true;
  }

  // add erc721 asset to the store, which adds a particular unique item from that erc721 to our catalogue
  function addNonFungibleChild(uint256 _tokenID, address _childContract, uint256 _index) isOngoing public returns (bool) {
    require(
      _childContract.call(
        bytes4(keccak256("transferFrom(address,address,uint256)")),
        msg.sender,
        _index
      )
    );
    address childToken = address(
      keccak256(abi.encodePacked(_childContract, _index))
    );

    // set as child
    children[_tokenID][childToken] = 1;
    return true;
  }

  // move an amount of erc20 from our catalogue to someone
  function moveFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _amount) internal returns (bool) {
    require(children[_tokenID][_childContract] >= _amount);
    require(
      _childContract.call(
        bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
        _to, _amount
      )
    );

    children[_tokenID][_childContract] -= _amount;
    return true;
  }

  // transfer a unique item from a erc721 in our catalogue to someone
  function moveNonFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _childTokenID) internal returns (bool) {
    address childToken = address(
      keccak256(abi.encodePacked(_childContract, _childTokenID))
    );
    require(children[_tokenID][childToken] == 1);
    require(
      _childContract.call(
        bytes4(keccak256(abi.encodePacked("transfer(address,uint256)"))),
        _to, _childTokenID
      )
    );

    children[_tokenID][childToken] = 0;
    return true;
  }

  // transfer an amount of erc20 from our catalogue to someone
  function transferFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _amount) isOngoing onlyRole(ROLE_CONTROLLER) internal returns (bool) {
    return moveFungibleChild(_to, _tokenID, _childContract, _amount);
  }

  // transfer a unique item from a erc721 in our catalogue to someone
  function transferNonFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _childTokenID) isOngoing onlyRole(ROLE_CONTROLLER) internal returns (bool) {
    return moveNonFungibleChild(_to, _tokenID, _childContract, _childTokenID);
  }

  function expireFungible(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _amount) onlyRole(ROLE_CONTROLLER) isClosed public returns (bool) {
    moveFungibleChild(_to, _tokenID, _childContract, _amount);
    emit Expired(address(this));
    return true;
  }

  function expireNonFungible(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _childTokenID) onlyRole(ROLE_CONTROLLER) isClosed public returns (bool){   
    moveNonFungibleChild(_to, _tokenID, _childContract, _childTokenID);
    emit Expired(address(this));
    return true;
  }

}
