pragma solidity ^0.4.24;

import './TwoKeyTypes.sol';
import "./GetCode.sol";
import "./TwoKeyAdmin.sol";
import "../interfaces/ITwoKeyReg.sol";

contract TwoKeyEventSource is TwoKeyTypes {

    /// Events
    event Created(address indexed _campaign, address indexed _owner);
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);
    event Escrow(address indexed _campaign, address indexed _converter, string assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Rewarded(address indexed _campaign, address indexed _to, uint256 _amount);
    event Fulfilled(address indexed _campaign, address indexed _converter, string indexed assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Cancelled(address indexed _campaign, address indexed _converter, string indexed assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type);
    event Rejected(address indexed _campaign, address indexed _converter);


    ///Address of the contract admin - interface
    TwoKeyAdmin twoKeyAdmin;

    /// Interface representing TwoKeyReg contract (Reducing gas usage that's why interface instead of contract instance)
    ITwoKeyReg interfaceTwoKeyReg;

    ///Mapping contract bytecode to boolean if is allowed to emit an event
    mapping(bytes => bool) canEmit;

    /// Mapping contract bytecode to enumerator CampaignType.
    mapping(bytes => CampaignType) codeToType;


    ///Mapping an address to boolean if allowed to modify
    mapping(address => bool) authorizedSubadmins;


    ///@notice Modifier which allows only admin to call a function - can be easily modified if there is going to be more admins
    modifier onlyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    ///@notice Modifier which allows all modifiers to update canEmit mapping - ever
    modifier onlyAuthorizedSubadmins {
        require(authorizedSubadmins[msg.sender] == true || msg.sender == address(twoKeyAdmin));
        _;
    }

    ///@notice Modifier which will only allow allowed contracts to emit an event
    modifier onlyAllowedContracts {
        //just to use contract code instead of msg.sender address
        bytes memory code = GetCode.at(msg.sender);
        require(canEmit[code] == true);
        _;
    }

    /// @notice Constructor during deployment of contract we need to set an admin address (means TwoKeyAdmin needs to be previously deployed)
    /// @param _twoKeyAdminAddress is the address of TwoKeyAdmin contract previously deployed
    constructor(address _twoKeyAdminAddress) public {
        twoKeyAdmin = TwoKeyAdmin(_twoKeyAdminAddress);
    }

    /// TODO: Put in constructor because of security issues (?)
    /// TODO: TwoKeyAdmin is owner
    /// TODO: Research about synchronization (concurrency)
    /// TODO: Bytecodes whitelist
    function addTwoKeyReg(address _twoKeyReg) public {
        interfaceTwoKeyReg = ITwoKeyReg(_twoKeyReg);
    }
    /// @notice function where admin or any authorized person (will be added if needed) can add more contracts to allow them call methods
    /// @param _contractAddress is actually the address of contract we'd like to allow
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function addContract(address _contractAddress) public onlyAuthorizedSubadmins {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = true;
    }

    /// @notice function where admin or any authorized person (will be added if needed) can remove contract (disable permissions to emit Events)
    /// @param _contractAddress is actually the address of contract we'd like to disable
    /// @dev We first fetch bytes32 contract code and then update our mapping
    /// @dev only admin can call this or an authorized person
    function removeContract(address _contractAddress) public onlyAuthorizedSubadmins {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = false;
    }

    /// @notice Function where an admin can authorize any other person to modify allowed contracts
    /// @param _newAddress is the address of new modifier contract / account
    /// @dev if only contract can be modifier then we'll add one more validation step
    function addAuthorizedAddress(address _newAddress) public {
        require(_newAddress != address(0));
        authorizedSubadmins[_newAddress] = true;
    }

    /// @notice Function to remove authorization from an modifier
    /// @param _authorizedAddress is the address of modifier
    /// @dev checking if that address is set to true before since we'll spend 21k gas if it's already false to override that value
    function removeAuthorizedAddress(address _authorizedAddress) public onlyAdmin {
        require(_authorizedAddress != address(0));
        require(authorizedSubadmins[_authorizedAddress] == true);

        authorizedSubadmins[_authorizedAddress] = false;
    }

    /// @notice Function to map contract code to type of campaign
    /// @dev is contract required to be allowed to emit to even exist in mapping codeToType
    /// @param _contractCode is code od contract
    /// @param _campaignType is enumerator representing type of campaign
    function addCampaignType(bytes _contractCode, CampaignType _campaignType) {
        require(canEmit[_contractCode] == true); //Check if this validation is needed
        codeToType[_contractCode] = _campaignType;
    }

    /// @notice Function where admin can be changed
    /// @param _newAdminAddress is the address of new admin
    /// @dev think about some security layer here
    function changeAdmin(address _newAdminAddress) public onlyAdmin {
        twoKeyAdmin = TwoKeyAdmin(_newAdminAddress);
    }

    function checkCanEmit(bytes _contractCode) public view returns (bool) {
        return canEmit[_contractCode];
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    /// This user will be contractor
    /// onlyAllowedContracts commented so Andri can fetch this
    function created(address _campaign, address _owner) public {
//        interfaceTwoKeyReg.addWhereContractor(_campaign, _owner);
    	emit Created(_campaign, _owner);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    /// This user will be refferer
    function joined(address _campaign, address _from, address _to) public onlyAllowedContracts {
        interfaceTwoKeyReg.addWhereReferrer(_campaign, _from);
    	emit Joined(_campaign, _from, _to);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function escrow(address _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts{
    	emit Escrow(_campaign, _converter, _assetName, _childContractID, _indexOrAmount, _type);
    }

    /// @dev Only allowed contracts can call this function ---> means can emit events
    function rewarded(address _campaign, address _to, uint256 _amount) public onlyAllowedContracts {
    	emit Rewarded(_campaign, _to, _amount);
	}

    /// @dev Only allowed contracts can call this function ---> means can emit events
	function fulfilled(address  _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts {
		emit Fulfilled(_campaign, _converter, _assetName, _childContractID, _indexOrAmount, _type);
	}

    /// @dev Only allowed contracts can call this function ---> means can emit events
	function cancelled(address  _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public onlyAllowedContracts{
		emit Cancelled(_campaign, _converter, _assetName, _childContractID, _indexOrAmount, _type);
	}


    function getAdmin() public view returns (address) {
        return address(twoKeyAdmin);
    }

    function checkIsAuthorized(address _subAdmin) public view returns (bool) {
        return authorizedSubadmins[_subAdmin];
    }
}