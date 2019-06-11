pragma solidity ^0.4.24;

import "../UpgradabilityProxyAcquisition.sol";

import '../interfaces/ITwoKeySingletonesRegistry.sol';
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/IStructuredStorage.sol";

import "../upgradability/UpgradabilityProxy.sol";
import "../upgradability/Upgradeable.sol";



/**
 * @author Nikola Madjarevic
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 * @notice Will be everything mapped by contract name, so we will easily update and get versions per contract, all stored here
 */
contract TwoKeySingletonesRegistry is ITwoKeySingletonesRegistry {

    mapping (string => mapping(string => address)) internal versionsLogic;
    mapping (string => mapping(string => address)) internal versionsStorage;
    address public deployer;

    mapping (string => address) contractNameToProxyLogicAddress;
    mapping (string => address) contractNameToProxyStorageAddress;

    mapping (string => string) contractNameToLatestVersionLogic;
    mapping (string => string) contractNameToLatestVersionStorage;

    mapping (string => address) nonUpgradableContractToAddress;


    event ProxiesDeployed(
        address logicProxy,
        address storageProxy
    );

    /**
     * @notice Calling super constructor from maintaining pattern
     */
    constructor()
    public
    {
        deployer = msg.sender;
    }

    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = contractNameToProxyLogicAddress["TwoKeyMaintainersRegistry"];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
    }


    function deployProxy(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version, msg.sender);
        emit ProxyCreated(proxy);
        return address(proxy);
    }


    function deployProxyLogic(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        address proxy = deployProxy(contractName, version);
        contractNameToProxyLogicAddress[contractName] = proxy;
        return proxy;
    }


    function deployProxyStorage(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        address proxy = deployProxy(contractName, version);
        contractNameToProxyStorageAddress[contractName] = proxy;
        return proxy;
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
    onlyMaintainer
    {
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }


    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    //TODO: Add event through event source whenever someone calls upgradeTo
    function addVersion(
        string contractName,
        string version,
        address implementation
    )
    public
    onlyMaintainer
    {
        require(versionsLogic[contractName][version] == 0x0);
        versionsLogic[contractName][version] = implementation;
        contractNameToLatestVersionLogic[contractName] = version;
        emit VersionAdded(version, implementation);
    }

    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addStorageVersion(
        string contractName,
        string version,
        address implementation
    )
    public
    onlyMaintainer
    {
        require(versionsStorage[contractName][version] == 0x0);
        versionsStorage[contractName][version] = implementation;
        contractNameToLatestVersionStorage[contractName] = version;
        emit VersionAdded(version, implementation);
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
        return versionsLogic[contractName][version];
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersionStorage(
        string contractName,
        string version
    )
    public
    view
    returns (address)
    {
        return versionsStorage[contractName][version];
    }


    /**
     * @notice Gets the latest contract version
     * @param contractName is the name of the contract
     * @return string representation of the last version
     */
    function getLatestContractVersion(
        string contractName
    )
    public
    view
    returns (string)
    {
        return contractNameToLatestVersionLogic[contractName];
    }

    /**
     * @notice Gets the latest contract version
     * @param contractName is the name of the contract
     * @return string representation of the last version
     */
    function getLatestContractStorageVersion(
        string contractName
    )
    public
    view
    returns (string)
    {
        return contractNameToLatestVersionStorage[contractName];
    }


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
        return contractNameToProxyLogicAddress[_contractName];
    }

    /**
     * @notice Function to return address of storage proxy for specific contract
     * @param _contractName is the name of the contract we'd like to get proxy address
     * @return is the address of the proxy for the specific contract
     */
    function getContractProxyStorageAddress(
        string _contractName
    )
    public
    view
    returns (address)
    {
        return contractNameToProxyStorageAddress[_contractName];
    }

    /**
     * @dev Creates an upgradeable proxy for both Storage and Logic
     * @param version representing the first version to be set for the proxy
     */
    function createProxy(
        string contractName,
        string version
    )
    public
    onlyMaintainer
    {
        address logicProxy = deployProxyLogic(contractName, version);
        address storageProxy = deployProxyStorage(contractName, version);

//        IStructuredStorage(storageProxy).setProxyLogicContractAndDeployer(logicProxy, msg.sender);

        emit ProxiesDeployed(logicProxy, storageProxy);
    }

    /**
     * @notice Function to create new proxy for logic contract
     * @param contractName is the name of the contract we're creating new proxy
     */
    function createProxyLogic(
        string contractName,
        string version
    )
    public
    onlyMaintainer
    returns (address)
    {
        return deployProxyLogic(contractName, version);
    }


    /**
     * @notice Function to create new proxy for storage contract
     * @param contractName is the name of the contract we're creating new proxy
     */
    function createProxyStorage(
        string contractName,
        string version
    )
    public
    onlyMaintainer
    returns (address)
    {
        return deployProxyStorage(contractName, version);
    }

}
