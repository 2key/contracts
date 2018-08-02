pragma solidity ^0.4.24;

// based on https://medium.com/coinmonks/introducing-crypto-composables-ee5701fde217

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './TwoKeyTypes.sol';

contract ComposableAssetFactory is Ownable, TwoKeyTypes {  

  event Expired(address indexed _contract);

  using SafeMath for uint256;

  uint256 private startTime;
  uint256 private duration;

  // now is less than duration after start time - so we are still live
  modifier isOngoing() {
    require(startTime + duration > now);
    _;
  }

  // now is more than duration after start time - so we are dead
  modifier isClosed() {
    require(startTime + duration <= now);
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

  
  // for each asset in store, we hold its capaign type
  struct Item {
    uint256 tokenID;
    address childContractID;
    CampaignType campaignType;
  }

  // list of items in store
  Item[] inventory;


  constructor(uint256 _start, uint256 _duration) Ownable() public {
    startTime = _start;
    duration = _duration;
  }

  // add asset to inventory list
  function addToInventory(uint256 _tokenID, address _childContract, CampaignType _type) internal {
  // _tokenID: shop keeping unit,  
    bool found; 
    for(uint256 i = 0; i < inventory.length; i++) { 
      if (inventory[i].tokenID == _tokenID) {
        found = true;
        break;
      }
    }
    if (!found) {
      inventory.push(Item(_tokenID, _childContract, _type));      
    }
  }

  // remove asset from inventory list
  function removeFromInventory(uint256 _tokenID) internal {
    for(uint256 i = 0; i < inventory.length; i++) { 
      if (inventory[i].tokenID == _tokenID) {
        uint256 currentLength = inventory.length;
        inventory[i] = inventory[currentLength - 1];
        delete inventory[currentLength - 1];
        inventory.length--;
        break;
      }
    }
  }

  // get type of item in inventory
  function getType(uint256 _tokenID) internal view returns (CampaignType)  {
    for(uint256 i = 0; i < inventory.length; i++) { 
      if (inventory[i].tokenID == _tokenID) {
        return inventory[i].campaignType;
      }
    }
    return CampaignType.None;
  }


  
  // add erc20 asset amount to the store, which adds an amount of that erc20 to our catalogue
  function addFungibleChild(uint256 _tokenID, address _childContract, uint256 _amount) public returns (bool) {
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
    addToInventory(_tokenID, _childContract, CampaignType.Fungible);
    return true;
  }

  // add erc721 asset to the store, which adds a particular unique item from that erc721 to our catalogue
  function addNonFungibleChild(uint256 _tokenID, address _childContract, uint256 _index) public returns (bool) {
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
    addToInventory(_tokenID, _childContract, CampaignType.NonFungible);
    return true;
  }


  // transfer an amount of erc20 from our catalogue to someone
  function transferFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _amount) onlyOwner public returns (bool) {
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
  function transferNonFungibleChild(
    address _to,
    uint256 _tokenID,
    address _childContract,
    uint256 _childTokenID) public onlyOwner returns (bool) {
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


  function expire(address _to) onlyOwner isClosed public {
    for(uint256 i = 0; i < inventory.length; i++) {
      Item memory item = inventory[i]; 
      if (item.campaignType == CampaignType.Fungible && children[item.tokenID][item.childContractID] == 1) {
        transferFungibleChild(_to, item.tokenID, item.childContractID, children[item.tokenID][item.childContractID]);
      } else  if (item.campaignType == CampaignType.NonFungible && children[item.tokenID][item.childContractID] > 0) {
        transferNonFungibleChild(_to, item.tokenID, item.childContractID, children[item.tokenID][item.childContractID]);
      }
    }
    selfdestruct(this);
    emit Expired(this);
  }

  // kill the contract, transfering everyting to the owner
  // Since the ERC721 and ERC20 store ownership by owner of this contract
  // that ownership need not be transferred
  function kill() public onlyOwner {        
      selfdestruct(owner);
  }

}
