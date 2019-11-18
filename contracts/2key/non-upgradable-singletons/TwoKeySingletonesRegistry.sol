pragma solidity ^0.4.24;

import "../UpgradabilityProxyAcquisition.sol";

import '../interfaces/ITwoKeySingletonesRegistry.sol';
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/IStructuredStorage.sol";

import "../upgradability/UpgradeabilityProxy.sol";
import "../upgradability/Upgradeable.sol";



/**
 * @author Nikola Madjarevic
 */
contract TwoKeySingletonesRegistry is ITwoKeySingletonesRegistry {

    address public deployer;

    mapping (string => mapping(string => address)) internal versions;
    mapping (string => address) contractNameToProxyAddress;
    mapping (string => string) contractNameToLatestVersion;
    mapping (string => address) nonUpgradableContractToAddress;


    event ProxiesDeployed(
        address logicProxy,
        address storageProxy
    );


    constructor()
    public
    {
        deployer = msg.sender;
    }

    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress["TwoKeyMaintainersRegistry"];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    modifier onlyCoreDev {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress["TwoKeyMaintainersRegistry"];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressCoreDev(msg.sender));
        _;
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
        require(nonUpgradableContractToAddress[contractName] == 0x0);
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }

    /**
     * @notice Function in case of hard fork, or congress replacement
     */
    function chanceNonUpgradableContract(
        string contractName,
        address contractAddress
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress["TwoKeyCongress"]);
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
        require(implementation != address(0));
        require(versions[contractName][version] == 0x0);
        versions[contractName][version] = implementation;
        contractNameToLatestVersion[contractName] = version;
        emit VersionAdded(version, implementation);
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
        require(keccak256(version) == keccak256("1.0.0"));

        versions[contractLogicName][version] = contractLogicImplementation;
        versions[contractStorageName][version] = contractStorageImplementation;

        contractNameToLatestVersion[contractLogicName] = version;
        contractNameToLatestVersion[contractStorageName] = version;
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
    function getLatestContractVersion(
        string contractName
    )
    public
    view
    returns (string)
    {
        return contractNameToLatestVersion[contractName];
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
        require(msg.sender == nonUpgradableContractToAddress["TwoKeyCongress"]);
        address proxyAddress = getContractProxyAddress(contractName);
        address _impl = getVersion(contractName, version);

        UpgradeabilityProxy(proxyAddress).upgradeTo(contractName, version, _impl);
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
