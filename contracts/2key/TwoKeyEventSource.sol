pragma solidity ^0.4.24;

import './TwoKeyTypes.sol';
import "./GetCode.sol";
import "../interfaces/ITwoKeyReg.sol";
import "./Upgradeable.sol";

contract TwoKeyEventSource is Upgradeable, TwoKeyTypes {

    /**
     * Address of TwoKeyRegistry contract
     */
    address twoKeyRegistry;

    /**
     * Mapping which will map contract code to true/false depending if that code is eligible to emit events
     */
    mapping(bytes => bool) canEmit;

    /**
     * Mapping which will store maintainers who are eligible to update contract state
     */
    mapping(address => bool) public isMaintainer;

    /**
     * Address of TwoKeyAdmin contract, which will be the only one eligible to manipulate the maintainers
     */
    address public twoKeyAdmin;


    event Created(
        address indexed _campaign,
        address indexed _owner,
        address indexed _moderator
    );

    event Joined(
        address indexed _campaign,
        address indexed _from,
        address indexed _to
    );

    event Converted(
        address indexed _campaign,
        address indexed _converter,
        uint256 _amount
    );

    event Rewarded(
        address indexed _campaign,
        address indexed _to,
        uint256 _amount
    );

    event Cancelled(
        address indexed _campaign,
        address indexed _converter,
        uint256 _indexOrAmount,
        CampaignType _type
    );

    event Rejected(
        address indexed _campaign,
        address indexed _converter
    );

    event UpdatedPublicMetaHash(
        uint timestamp,
        string value
    );

    event UpdatedData(
        uint timestamp,
        uint value,
        string action
    );

    event ReceivedEther(
        address _sender,
        uint value
    );


    /**
     * @notice Modifier to restrict calling the method to anyone but maintainers
     */
    modifier onlyMaintainer {
        require(isMaintainer[msg.sender] == true);
        _;
    }

    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    modifier onlyTwoKeyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    /**
     * @notice Modifier to restrict calling the method to anyone but authorized people
     */
    modifier onlyMaintainerOrTwoKeyAdmin {
        require(isMaintainer[msg.sender] == true || msg.sender == address(twoKeyAdmin));
        _;
    }

    /**
     * Modifier which will allow only specific contracts to emit events
     */
    modifier onlyAllowedContracts {
        bytes memory code = GetCode.at(msg.sender);
        require(canEmit[code] == true,'Contract code is not supported to emit the events');
        _;
    }

    /**
     * @notice Function to set initial params in the contract
     * @param _twoKeyAdmin is the address of twoKeyAdmin contract
     * @param _maintainers is the array containing addresses of maintainers
     * @param _twoKeyRegistry is the address of twoKeyRegistry contract
     */
    function setInitialParams(address _twoKeyAdmin, address [] _maintainers, address _twoKeyRegistry) external {
        require(twoKeyAdmin == address(0));
        twoKeyAdmin = _twoKeyAdmin;
        twoKeyRegistry = _twoKeyRegistry;
        isMaintainer[msg.sender] = true; //also the deployer will be authorized maintainer
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }


    /**
     * @notice function where admin or any maintainer can add more contracts to allow them call methods
     * @param _contractAddress is actually the address of contract we'd like to allow
     * @dev We first fetch bytes contract code and then update our mapping
     * @dev only admin can call this or an authorized person
     */
    function addContract(address _contractAddress) external onlyMaintainerOrTwoKeyAdmin {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = true;
    }


    /**
     * @notice function where admin or any maintainer can remove contract from whitelist
     * @param _contractAddress is actually the address of contract we'd like to disallow
     * @dev We first fetch bytes contract code and then update our mapping
     * @dev only admin can call this or an authorized person
     */
    function removeContract(address _contractAddress) external onlyMaintainerOrTwoKeyAdmin {
        require(_contractAddress != address(0));
        bytes memory _contractCode = GetCode.at(_contractAddress);
        canEmit[_contractCode] = false;
    }

    /**
    * @notice Function which can add new maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
    * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
    * @param _maintainers is the array of maintainer addresses
    */
    function addMaintainers(address [] _maintainers) external onlyTwoKeyAdmin {
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(address [] _maintainers) external onlyTwoKeyAdmin {
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }

    /**
     * @notice Function to emit created event every time campaign is created
     * @param _campaign is the address of the deployed campaign
     * @param _owner is the contractor address of the campaign
     * @param _moderator is the address of the moderator in campaign
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function created(address _campaign, address _owner, address _moderator) external {
        //TODO: Add validation layer for this function
        ITwoKeyReg(twoKeyRegistry).addWhereContractor(_owner, _campaign);
        ITwoKeyReg(twoKeyRegistry).addWhereModerator(_moderator, _campaign);
        emit Created(_campaign, _owner, _moderator);
    }

    /**
     * @notice Function to emit created event every time someone has joined to campaign
     * @param _campaign is the address of the deployed campaign
     * @param _from is the address of the referrer
     * @param _to is the address of person who has joined
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function joined(address _campaign, address _from, address _to) external onlyAllowedContracts {
        ITwoKeyReg(twoKeyRegistry).addWhereReferrer(_campaign, _from);
        emit Joined(_campaign, _from, _to);
    }

    /**
     * @notice Function to emit created event every time conversion happened
     * @param _campaign is the address of the deployed campaign
     * @param _converter is the converter address
     * @param _amountETHWei is the conversion amount
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function converted(address _campaign, address _converter, uint256 _amountETHWei) external onlyAllowedContracts {
        ITwoKeyReg(twoKeyRegistry).addWhereConverter(_converter, _campaign);
        emit Converted(_campaign, _converter, _amountETHWei);
    }

    /**
     * @notice Function to emit created event every time reward happened
     * @param _campaign is the address of the deployed campaign
     * @param _to is the reward receiver
     * @param _amount is the reward amount
     */
    function rewarded(address _campaign, address _to, uint256 _amount) external onlyAllowedContracts {
        emit Rewarded(_campaign, _to, _amount);
    }

    /**
     * @notice Function to emit created event every time campaign is cancelled
     * @param _campaign is the address of the cancelled campaign
     * @param _converter is the address of the converter
     * @param _indexOrAmount is the amount of campaign
     * @param _type is the campaign type
     */
    function cancelled(address  _campaign, address _converter, uint256 _indexOrAmount, CampaignType _type) external onlyAllowedContracts{
        emit Cancelled(_campaign, _converter, _indexOrAmount, _type);
    }

    /**
     * @notice Function which will emit updated public meta hash event
     * @param timestamp is the moment of execution
     * @param value is the new value of public meta hash (in this case it's ipfs hash bytes32)
     */
    function updatedPublicMetaHash(uint timestamp, string value) external onlyAllowedContracts {
        emit UpdatedPublicMetaHash(timestamp, value);
    }

    /**
     * @notice Function which will emit updated data event
     * @param timestamp is the moment of execution
     * @param value is the new value
     * @param action is the string describing action what was updated exactly
     */
    function updatedData(uint timestamp, uint value, string action) external onlyAllowedContracts {
        emit UpdatedData(timestamp, value, action);
    }

    /**
     * @notice Function to check if the contract deployed at passed address is eligible to emit events through this contract
     * @param _contractAddress is the address of contract we're checking
     * @return true if eligible otherwise will return false
     */
    function isAddressWhitelistedToEmitEvents(address _contractAddress) external view returns (bool) {
        bytes memory code = GetCode.at(_contractAddress);
        return canEmit[code];
    }

    /**
     * @notice Function to determine plasma address of ethereum address
     * @param me is the address (ethereum) of the user
     * @return an address
     */
    function plasmaOf(address me) public view returns (address) {
        if (twoKeyRegistry == address(0)) {
            me;
        }
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(address me) public view returns (address) {
        if (twoKeyRegistry == address(0)) {
            return me;
        }
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    /**
     * @notice Address to check if an address is maintainer in registry
     * @param _maintainer is the address we're checking this for
     */
    function isAddressMaintainer(address _maintainer) public view returns (address) {
        bool isMaintainer = ITwoKeyReg(twoKeyRegistry).checkIfTwoKeyMaintainerExists(_maintainer);
        return isMaintainer;
    }

}