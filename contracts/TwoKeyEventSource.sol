pragma solidity ^0.4.24;

import './TwoKeyTypes.sol';

contract TwoKeyEventSource is TwoKeyTypes {

    event Created(address indexed _campaign, address indexed _contractor);  
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);  
	event Escrow(address indexed _campaign, address indexed _converter, uint256 _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type);
	event Rewarded(address indexed _campaign, address indexed _to, uint256 _amount);
    event Fulfilled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type);
    event Cancelled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type);

    function created(address _campaign, address _contractor) public {
    	emit Created(_campaign, _contractor);
    }

    function joined(address _campaign, address _from, address _to) public {
    	emit Joined(_campaign, _from, _to);
    }

    function escrow(address _campaign, address _converter, uint256 _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type) public {
    	emit Escrow(_campaign, _converter, _tokenID, _assetContractID, _indexOrAmount, _type);
    }

    function rewarded(address _campaign, address _to, uint256 _amount) public {
    	emit Rewarded(_campaign, _to, _amount);
	}

	function fulfilled(address  _campaign, address _converter, uint256 _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type) public {
		emit Fulfilled(_campaign, _converter, _tokenID, _assetContractID, _indexOrAmount, _type);
	}

	function cancelled(address _campaign, address _converter, uint256 _tokenID, address _assetContractID, uint256 _indexOrAmount, CampaignType _type) public {
		emit Cancelled(_campaign, _converter, _tokenID, _assetContractID, _indexOrAmount, _type);
	}

}