pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletonesRegistry.sol";
import "../interfaces/IStructuredStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../upgradability/UpgradeabilityProxy.sol";
import "../upgradability/Upgradeable.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyPlasmaSingletoneRegistry is ITwoKeySingletonesRegistry {

    address public deployer;

    mapping (string => mapping(string => address)) internal versions;
    mapping (string => address) contractToProxy;
    mapping (string => string) contractNameToLatestVersionName;

    event ProxiesDeployed(
        address logicProxy,
        address storageProxy
    );

    constructor() public {
        deployer = msg.sender;
    }

    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = contractToProxy["TwoKeyPlasmaMaintainersRegistry"];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
    }

    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addVersion(string contractName, string version, address implementation) public onlyMaintainer {
        require(versions[contractName][version] == 0x0);
        versions[contractName][version] = implementation;
        contractNameToLatestVersionName[contractName] = version;
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
    onlyMaintainer
    {
        // Can be called only when we're creating first time contracts
        require(keccak256(version) == keccak256("1.0.0"));

        versions[contractLogicName][version] = contractLogicImplementation;
        versions[contractStorageName][version] = contractStorageImplementation;

        contractNameToLatestVersionName[contractLogicName] = version;
        contractNameToLatestVersionName[contractStorageName] = version;
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersion(string contractName, string version) public view returns (address) {
        return versions[contractName][version];
    }

    /**
     * @notice Gets the latest contract version
     * @param contractName is the name of the contract
     * @return string representation of the last version
     */
    function getLatestContractVersion(string contractName) public view returns (string) {
        return contractNameToLatestVersionName[contractName];
    }

    /**
     * @notice Function to return address of proxy for specific contract
     * @param _contractName is the name of the contract we'd like to get proxy address
     * @return is the address of the proxy for the specific contract
     */
    function getContractProxyAddress(string _contractName) public view returns (address) {
        return contractToProxy[_contractName];
    }

    function deployProxy(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version);
        contractToProxy[contractName] = proxy;
        return address(proxy);
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
    onlyMaintainer
    {
        address logicProxy = deployProxy(contractName, version);
        address storageProxy = deployProxy(contractNameStorage, version);

        IStructuredStorage(storageProxy).setProxyLogicContractAndDeployer(logicProxy, msg.sender);
        emit ProxiesDeployed(logicProxy, storageProxy);
    }

    function upgradeContract(
        string contractName,
        string version
    )
    public
    {
        require(msg.sender == deployer);
        address proxyAddress = getContractProxyAddress(contractName);
        address _impl = getVersion(contractName, version);
        UpgradeabilityProxy(proxyAddress).upgradeTo(contractName, version, _impl);
    }

}
