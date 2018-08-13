pragma solidity ^0.4.24;

import './TwoKeyTypes.sol';
import "./TwoKeyAdmin.sol";
import "./GetCode.sol";


contract TwoKeyEventSource is TwoKeyTypes {

    /// Events
    event Created(address indexed _campaign, address indexed _owner);
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);
    event Escrow(address indexed _campaign, address indexed _escrow, address indexed _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Rewarded(address indexed _campaign, address indexed _to, uint256 _amount);
    event Fulfilled(address indexed _campaign, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Cancelled(address indexed _escrow, address indexed _converter, uint256 indexed _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type);


    ///Address of the contract admin
    TwoKeyAdmin twoKeyAdmin;

    ///Mapping contract bytecode to boolean if is allowed to emit an event
    mapping(bytes => bool) canEmit;

    ///Mapping an address to boolean if allowed to modify
    mapping(address => bool) allowedModifiers;

    ///@notice Modifier which allows only admin to call a function - can be easily modified if there is going to be more admins
    modifier onlyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    ///@notice Modifier which allows all modifiers to update canEmit mapping - ever
    modifier onlyAllowedModifiers {
        require(allowedModifiers[msg.sender] == true || msg.sender == address(twoKeyAdmin));
        _;
    }

    ///@notice Modifier which will only allow allowed contracts to emit an event
    modifier onlyAllowedContracts {
        //just to use contract code instead of msg.sender address
        bytes memory code = GetCode.at(msg.sender);
        require(canEmit[code] == true);
        _;
    }

    /// @notice function where admin or any authorized person (will be added if needed) can add more contracts to allow them call methods
    /// @param _contractAddress is actually the address of contract we'd like to allow
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function addContract(address _contractAddress) public onlyAllowedModifiers {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = true;
    }

    /// @notice function where admin or any authorized person (will be added if needed) can remove contract (disable permissions to emit Events)
    /// @param _contractAddress is actually the address of contract we'd like to disable
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function removeContract(address _contractAddress) public onlyAllowedModifiers {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = false;
    }

    /// @notice Function where an admin can authorize any other person to modify allowed contracts
    /// @param _newModifier is the address of new modifier contract / account
    /// @dev if only contract can be modifier then we'll add one more validation step
    function addModifier(address _newModifier) public onlyAdmin {
        require(_newModifier != address(0));
        allowedModifiers[_newModifier] = true;
    }

    /// @notice Function to remove authorization from an modifier
    /// @param _oldModifier is the address of modifier
    /// @dev checking if that address is set to true before since we'll spend 21k gas if it's already false to override that value
    function removeModifier(address _oldModifier) public onlyAdmin {
        require(_oldModifier != address(0));
        require(allowedModifiers[_oldModifier] == true);

        allowedModifiers[_oldModifier] = false;
    }
    /// @notice Constructor during deployment of contract we need to set an admin address (means TwoKeyAdmin needs to be previously deployed)
    /// @param _twoKeyAdminAddress is the address of TwoKeyAdmin contract previously deployed
    constructor(address _twoKeyAdminAddress) public {
        twoKeyAdmin = TwoKeyAdmin(_twoKeyAdminAddress);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function created(address _campaign, address _owner) public onlyAllowedContracts{
    	emit Created(_campaign, _owner);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function joined(address _campaign, address _from, address _to) public onlyAllowedContracts{
    	emit Joined(_campaign, _from, _to);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function escrow(address _campaign, address _escrow, address _sender, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts{
    	emit Escrow(_campaign, _escrow, _sender, _tokenID, _childContractID, _indexOrAmount, _type);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function rewarded(address _campaign, address _to, uint256 _amount) public onlyAllowedContracts {
    	emit Rewarded(_campaign, _to, _amount);
	}

    /// @dev Only allowed contracts can call this function ---> means can emit events
	function fulfilled(address  _campaign, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts {
		emit Fulfilled(_campaign, _converter, _tokenID, _childContractID, _indexOrAmount, _type);
	}

    /// @dev Only allowed contracts can call this function ---> means can emit events
	function cancelled(address  _escrow, address _converter, uint256 _tokenID, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts{
		emit Cancelled(_escrow, _converter, _tokenID, _childContractID, _indexOrAmount, _type);
	}

}