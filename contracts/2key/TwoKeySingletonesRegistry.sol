pragma solidity ^0.4.24;

import './ITwoKeySingletonesRegistry.sol';
import './Upgradeable.sol';
import "./UpgradabilityProxy.sol";
import "./MaintainingPattern.sol";

/**
 * @author Nikola Madjarevic
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 * @notice Will be everything mapped by contract name, so we will easily update and get versions per contract, all stored here
 */
contract TwoKeySingletonesRegistry is MaintainingPattern, ITwoKeySingletonesRegistry {
    // Mapping of contract name to versions to implementations of different functions
    mapping (string => mapping(string => address)) internal versions;
    mapping (string => address) contractToProxy;

    /**
     * @notice Calling super constructor from maintaining pattern
     */
    constructor(address [] _maintainers, address _twoKeyAdmin) MaintainingPattern(_maintainers, _twoKeyAdmin) public {

    }

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string contractName, string version, address implementation) public onlyMaintainer {
        require(versions[contractName][version] == 0x0);
        versions[contractName][version] = implementation;
        emit VersionAdded(version, implementation);
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
     * @notice Function to return address of proxy for specific contract
     * @param _contractName is the name of the contract we'd like to get proxy address
     * @return is the address of the proxy for the specific contract
     */
    function getContractProxyAddress(string _contractName) public view returns (address) {
        return contractToProxy[_contractName];
    }

    /**
    * @dev Creates an upgradeable proxy
    * @param version representing the first version to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(string contractName, string version) public onlyMaintainer payable returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        contractToProxy[contractName] = proxy;
        emit ProxyCreated(proxy);
        return proxy;
    }
}