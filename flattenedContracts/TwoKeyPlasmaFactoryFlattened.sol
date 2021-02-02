pragma solidity ^0.4.13;

contract IHandleCampaignDeploymentPlasma {

    function setInitialParamsCPCCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        string _url,
        uint [] numberValues
    )
    public;

    function setInitialParamsCPCCampaignPlasmaNoRewards(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        string _url,
        uint [] numberValues
    )
    public;
}

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyPlasmaEventSource {
    function emitPlasma2EthereumEvent(address _plasma, address _ethereum) public;

    function emitPlasma2HandleEvent(address _plasma, string _handle) public;

    function emitCPCCampaignCreatedEvent(address proxyCPCCampaignPlasma, address contractorPlasma) public;

    function emitConversionCreatedEvent(address campaignAddressPublic, uint conversionID, address contractor, address converter) public;

    function emitConversionExecutedEvent(uint conversionID) public;

    function emitConversionRejectedEvent(uint conversionID, uint statusCode) public;

    function emitCPCCampaignMirrored(address proxyAddressPlasma, address proxyAddressPublic) public;

    function emitHandleChangedEvent(address _userPlasmaAddress, string _newHandle) public;

    function emitConversionPaidEvent(uint conversionID) public;

    function emitAddedPendingRewards(address campaignPlasma, address influencer, uint amountOfTokens) public;

    function emitRewardsAssignedToUserInParticipationMiningEpoch(uint epochId, address user, uint reward2KeyWei) public;

    function emitEpochDeclared(uint epochId, uint totalRewardsInEpoch) public;

    function emitEpochRegistered(uint epochId, uint numberOfUsers) public;

    function emitEpochFinalized(uint epochId) public;

    function emitPaidPendingRewards(
        address influencer,
        uint amountNonRebalancedReferrerEarned,
        uint amountPaid,
        address[] campaignsPaid,
        uint [] earningsPerCampaign,
        uint feePerReferrer2KEY
    ) public;

}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract ITwoKeyPlasmaFactoryStorage is IStructuredStorage {

}

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    /**
     * @notice Function to get any singleton contract proxy address from TwoKeySingletonRegistry contract
     * @param contractName is the name of the contract we're looking for
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function getNonUpgradableContractAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(contractName);
    }
}

contract Proxy {


    // Gives the possibility to delegate any call to a foreign implementation.


    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyPlasmaFactory is Upgradeable {

    bool initialized;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _addressToCampaignType = "addressToCampaignType";
    string constant _isCampaignCreatedThroughFactory = "isCampaignCreatedThroughFactory";
    string constant _campaignAddressToNonSingletonHash = "campaignAddressToNonSingletonHash";

    ITwoKeyPlasmaFactoryStorage PROXY_STORAGE_CONTRACT;


    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaFactoryStorage(_proxyStorage);

        initialized = true;
    }


    function getLatestApprovedCampaignVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getLatestCampaignApprovedVersion(campaignType);
    }


    function createProxyForCampaign(
        string campaignType,
        string campaignName
    )
    internal
    returns (address)
    {
        ProxyCampaign proxy = new ProxyCampaign(
            campaignName,
            getLatestApprovedCampaignVersion(campaignType),
            address(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        );

        return address(proxy);
    }

    function createPlasmaCPCCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        address proxyPlasmaCPC = createProxyForCampaign("CPC_PLASMA", "TwoKeyCPCCampaignPlasma");

        IHandleCampaignDeploymentPlasma(proxyPlasmaCPC).setInitialParamsCPCCampaignPlasma(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );

        setCampaignToNonSingletonHash(proxyPlasmaCPC, _nonSingletonHash);
        setCampaignCreatedThroughFactory(proxyPlasmaCPC);
        setAddressToCampaignType(proxyPlasmaCPC, "CPC_PLASMA");
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(proxyPlasmaCPC, msg.sender);
    }

    function createPlasmaCPCNoRewardsCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        address proxyPlasmaCPCNoRewards = createProxyForCampaign("CPC_NO_REWARDS_PLASMA","TwoKeyCPCCampaignPlasmaNoReward");

        IHandleCampaignDeploymentPlasma(proxyPlasmaCPCNoRewards).setInitialParamsCPCCampaignPlasmaNoRewards(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );

        setCampaignToNonSingletonHash(proxyPlasmaCPCNoRewards, _nonSingletonHash);
        setCampaignCreatedThroughFactory(proxyPlasmaCPCNoRewards);
        setAddressToCampaignType(proxyPlasmaCPCNoRewards, "CPC_NO_REWARDS_PLASMA");
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(proxyPlasmaCPCNoRewards, msg.sender);
    }

    /**
     * @notice          For PPC campaigns we store their non singleton hash
     * @param           _campaignAddress is the address of campaign
     * @param           _nonSingletonHash is the non singleton hash
     */
    function setCampaignToNonSingletonHash(
        address _campaignAddress,
        string _nonSingletonHash
    )
    internal
    {
        bytes32 key = keccak256(_campaignAddressToNonSingletonHash,_campaignAddress);
        PROXY_STORAGE_CONTRACT.setString(key, _nonSingletonHash);
    }

    /**
     * @notice Internal function which will set that campaign is created through the factory
     * and whitelist that address
     * @param _campaignAddress is the campaign we want to set this rule
     */
    function setCampaignCreatedThroughFactory(
        address _campaignAddress
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignCreatedThroughFactory, _campaignAddress), true);
    }

    /**
     * @notice Getter to check if the campaign is created through TwoKeyPlasmaFactory
     * which will whitelist it to emit all the events through TwoKeyPlasmaEvents
     * @param _campaignAddress is the address of the campaign we want to check
     */
    function isCampaignCreatedThroughFactory(
        address _campaignAddress
    )
    public
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(keccak256(_isCampaignCreatedThroughFactory, _campaignAddress));
    }

    /**
     * @notice          Getter to return the non singleton hash assigned to campaign
     * @param           campaignAddress is the address of campaign
     */
    function getNonSingletonHashForCampaign(
        address campaignAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_campaignAddressToNonSingletonHash, campaignAddress));
    }

    /**
     * @notice internal function to set address to campaign type
     * @param _campaignAddress is the address of campaign
     * @param _campaignType is the type of campaign (String)
     */
    function setAddressToCampaignType(address _campaignAddress, string _campaignType) internal {
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToCampaignType, _campaignAddress), _campaignType);
    }

    /**
     * @notice Function working as a getter
     * @param _key is the address of campaign
     */
    function addressToCampaignType(address _key) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToCampaignType, _key));
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

}

contract UpgradeabilityCampaignStorage {

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract ProxyCampaign is Proxy, UpgradeabilityCampaignStorage {

    constructor (string _contractName, string _version, address twoKeySingletonRegistry) public {
        _implementation = ITwoKeySingletonesRegistry(twoKeySingletonRegistry).getVersion(_contractName, _version);
    }
}

