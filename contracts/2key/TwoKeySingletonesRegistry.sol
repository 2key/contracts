pragma solidity ^0.4.24;

import './ITwoKeySingletonesRegistry.sol';
import './Upgradeable.sol';
import "./UpgradabilityProxy.sol";
import "./MaintainingPattern.sol";

/**
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 * @notice Will be everything mapped by contract name, so we will easily update and get versions per contract, all stored here
 */
contract TwoKeySingletonesRegistry is MaintainingPattern, ITwoKeySingletonesRegistry {
    // Mapping of versions to implementations of different functions
    mapping (string => address) internal versions;

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
    function addVersion(string version, address implementation) public onlyMaintainer {
        require(versions[version] == 0x0);
        versions[version] = implementation;
        VersionAdded(version, implementation);
    }

    /**
    * @dev Tells the address of the implementation for a given version
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string version) public view returns (address) {
        return versions[version];
    }

    /**
    * @dev Creates an upgradeable proxy
    * @param version representing the first version to be set for the proxy
    * @return address of the new proxy created
    */
    function createProxy(string version) public onlyMaintainer payable returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(version);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        ProxyCreated(proxy);
        return proxy;
    }
}