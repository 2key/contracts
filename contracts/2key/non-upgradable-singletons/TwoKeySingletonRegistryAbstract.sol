pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletonesRegistry.sol";
import "../upgradability/UpgradeabilityProxy.sol";
import "../interfaces/IStructuredStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../upgradability/UpgradeabilityProxy.sol";
import "../upgradability/Upgradeable.sol";
/**
 * @author Nikola Madjarevic
 */
contract TwoKeySingletonRegistryAbstract is ITwoKeySingletonesRegistry {

    address public deployer;

    string congress;
    string maintainersRegistry;

    mapping (string => mapping(string => address)) internal versions;

    mapping (string => address) contractNameToProxyAddress;
    mapping (string => string) contractNameToLatestAddedVersion;
    mapping (string => address) nonUpgradableContractToAddress;
    mapping (string => string) campaignTypeToLastApprovedVersion;


    event ProxiesDeployed(
        address logicProxy,
        address storageProxy
    );

    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress[maintainersRegistry];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    modifier onlyCoreDev {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress[maintainersRegistry];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressCoreDev(msg.sender));
        _;
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersion(
        string contractName,
        string version
    )
    public
    view
    returns (address)
    {
        return versions[contractName][version];
    }



    /**
     * @notice Gets the latest contract version
     * @param contractName is the name of the contract
     * @return string representation of the last version
     */
    function getLatestAddedContractVersion(
        string contractName
    )
    public
    view
    returns (string)
    {
        return contractNameToLatestAddedVersion[contractName];
    }


    /**
     * @notice Function to get address of non-upgradable contract
     * @param contractName is the name of the contract
     */
    function getNonUpgradableContractAddress(
        string contractName
    )
    public
    view
    returns (address)
    {
        return nonUpgradableContractToAddress[contractName];
    }

    /**
     * @notice Function to return address of proxy for specific contract
     * @param _contractName is the name of the contract we'd like to get proxy address
     * @return is the address of the proxy for the specific contract
     */
    function getContractProxyAddress(
        string _contractName
    )
    public
    view
    returns (address)
    {
        return contractNameToProxyAddress[_contractName];
    }

    /**
     * @notice Function to get latest campaign approved version
     * @param campaignType is type of campaign
     */
    function getLatestCampaignApprovedVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return campaignTypeToLastApprovedVersion[campaignType];
    }


    /**
     * @notice Function to add non upgradable contract in registry of all contracts
     * @param contractName is the name of the contract
     * @param contractAddress is the contract address
     * @dev only maintainer can issue call to this method
     */
    function addNonUpgradableContractToAddress(
        string contractName,
        address contractAddress
    )
    public
    onlyCoreDev
    {
        require(nonUpgradableContractToAddress[contractName] == 0x0);
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }

    /**
     * @notice Function in case of hard fork, or congress replacement
     * @param contractName is the name of contract we want to add
     * @param contractAddress is the address of contract
     */
    function changeNonUpgradableContract(
        string contractName,
        address contractAddress
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }


    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addVersion(
        string contractName,
        string version,
        address implementation
    )
    public
    onlyCoreDev
    {
        require(implementation != address(0)); //Require that version implementation is not 0x0
        require(versions[contractName][version] == 0x0); //No overriding of existing versions
        versions[contractName][version] = implementation; //Save the version for the campaign
        contractNameToLatestAddedVersion[contractName] = version;
        emit VersionAdded(version, implementation, contractName);
    }

    function addVersionDuringCreation(
        string contractLogicName,
        string contractStorageName,
        address contractLogicImplementation,
        address contractStorageImplementation,
        string version
    )
    public
    {
        require(msg.sender == deployer);
        bytes memory logicVersion = bytes(contractNameToLatestAddedVersion[contractLogicName]);
        bytes memory storageVersion = bytes(contractNameToLatestAddedVersion[contractStorageName]);

        require(logicVersion.length == 0 && storageVersion.length == 0); //Requiring that this is first time adding a version
        require(keccak256(version) == keccak256("1.0.0")); //Requiring that first version is 1.0.0

        versions[contractLogicName][version] = contractLogicImplementation; //Storing version
        versions[contractStorageName][version] = contractStorageImplementation; //Storing version

        contractNameToLatestAddedVersion[contractLogicName] = version; // Mapping latest contract name to the version
        contractNameToLatestAddedVersion[contractStorageName] = version; //Mapping latest contract name to the version
    }

    /**
     * @notice Internal function to deploy proxy for the contract
     * @param contractName is the name of the contract
     * @param version is the new version
     */
    function deployProxy(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version);
        contractNameToProxyAddress[contractName] = proxy;
        emit ProxyCreated(proxy);
        return address(proxy);
    }

    /**
     * @notice Function to upgrade contract to new version
     * @param contractName is the name of the contract
     * @param version is the new version
     */
    function upgradeContract(
        string contractName,
        string version
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        address proxyAddress = getContractProxyAddress(contractName);
        address _impl = getVersion(contractName, version);

        UpgradeabilityProxy(proxyAddress).upgradeTo(contractName, version, _impl);
    }

    /**
     * @notice Function to approve campaign version per type during it's creation
     * @param campaignType is the type of campaign we want to approve during creation
     */
    function approveCampaignVersionDuringCreation(
        string campaignType
    )
    public
    onlyCoreDev
    {
        bytes memory campaign = bytes(campaignTypeToLastApprovedVersion[campaignType]);

        require(campaign.length == 0);

        campaignTypeToLastApprovedVersion[campaignType] = "1.0.0";
    }

    /**
     * @notice Function to approve selected version for specific type of campaign
     * @param campaignType is the type of campaign
     * @param versionToApprove is the version for that type we want to approve
     */
    function approveCampaignVersion(
        string campaignType,
        string versionToApprove
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        campaignTypeToLastApprovedVersion[campaignType] = versionToApprove;
    }

    /**
     * @dev Creates an upgradeable proxy for both Storage and Logic
     * @param version representing the first version to be set for the proxy
     */
    function createProxy(
        string contractName,
        string contractNameStorage,
        string version
    )
    public
    {
        require(msg.sender == deployer);
        require(contractNameToProxyAddress[contractName] == address(0));
        address logicProxy = deployProxy(contractName, version);
        address storageProxy = deployProxy(contractNameStorage, version);

        IStructuredStorage(storageProxy).setProxyLogicContractAndDeployer(logicProxy, msg.sender);
        emit ProxiesDeployed(logicProxy, storageProxy);
    }

    /**
     * @notice Function to transfer deployer privileges to another address
     * @param _newOwner is the new contract "owner" (called deployer in this case)
     */
    function transferOwnership(
        address _newOwner
    )
    public
    {
        require(msg.sender == deployer);
        deployer = _newOwner;
    }



}
