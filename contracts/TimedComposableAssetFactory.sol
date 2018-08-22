pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import './ComposableAssetFactory.sol';
import './Timed.sol';

contract TimedComposableAssetFactory is Timed, ComposableAssetFactory {

	event Expired(address indexed _contract);

	ERC20 public token;

	constructor(uint256 _start, uint256 _duration) Timed(_start, _duration) ComposableAssetFactory()  public {

	}

	function expire(address _to) onlyOwner isClosed public {
	    for(uint256 i = 0; i < inventory.length; i++) {
	      Item memory item = inventory[i]; 
	      if (item.campaignType == CampaignType.Fungible && children[item.tokenID][item.childContractID] == 1) {
	        transferNonFungibleChild(_to, item.tokenID, item.childContractID, children[item.tokenID][item.childContractID]);
	      } else  if (item.campaignType == CampaignType.NonFungible && children[item.tokenID][item.childContractID] > 0) {
	        transferNonFungibleChild(_to, item.tokenID, item.childContractID, children[item.tokenID][item.childContractID]);
	      }
	    }
	    token.transfer(owner, token.balanceOf(this));
	    selfdestruct(this);
	    emit Expired(this);
	}
}