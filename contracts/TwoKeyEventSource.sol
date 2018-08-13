pragma solidity ^0.4.24;

import './TwoKeyTypes.sol';

contract TwoKeyEventSource is TwoKeyTypes {
    ///Address of the contract admin
    TwoKeyAdmin twoKeyAdmin;

    ///Mapping contract bytecode to boolean if is allowed to emit an event
    mapping(bytes32 => bool) canEmit;


    ///@notice Modifier which allows only admin to call a function - can be easily modified if there is going to be more admins
    modifier onlyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }


    ///@notice Modifier which will only allow allowed contracts to emit an event
    modifier onlyAllowedContracts {
        //just to use contract code instead of msg.sender address
        require(canEmit(msg.sender) == true);
        _;
    }

    /// @notice function where admin or any authorized person (will be added if needed) can add more contracts to allow them call methods
    /// @param _contractAddress is actually the address of contract we'd like to allow
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function addContract(address _contractAddress) public onlyAdmin {
        bytes32 _contractCode;
        canEmit[_contractCode] = true;
    }

    /// @notice function where admin or any authorized person (will be added if needed) can remove contract (disable permissions to emit Events)
    /// @param _contractAddress is actually the address of contract we'd like to disable
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function removeContract(address _contractAddress) public onlyAdmin {
        bytes32 _contractCode;
        canEmit[_contractCode] = false;
    }

    constructor(address _twoKeyAdminAddress) public {
        twoKeyAdmin = TwoKeyAdmin(_twoKeyAdminAddress);
    }

    event Created(address indexed _campaign, address indexed _owner);
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);
	event Escrow(address indexed _campaign, address indexed _escrow, address indexed _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
	event Rewarded(address indexed _campaign, address indexed _to, uint256 _amount);
    event Fulfilled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Cancelled(address indexed _escrow, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);

    function created(address _campaign, address _owner) public {
    	emit Created(_campaign, _owner);
    }

    function joined(address _campaign, address _from, address _to) public {
    	emit Joined(_campaign, _from, _to);
    }

    function escrow(address _campaign, address _escrow, address _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public {
    	emit Escrow(_campaign, _escrow, _sender, _tokenID, _childContractID, _indexOrAmount, _type);
    }

    function rewarded(address _campaign, address _to, uint256 _amount) public {
    	emit Rewarded(_campaign, _to, _amount);
	}

	function fulfilled(address  _campaign, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public {
		emit Fulfilled(_campaign, _converter, _tokenID, _childContractID, _indexOrAmount, _type);
	}

	function cancelled(address  _escrow, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public {
		emit Cancelled(_escrow, _converter, _tokenID, _childContractID, _indexOrAmount, _type);
	}

}