pragma solidity ^0.4.18;

import './Proxy.sol';
import './ITwoKeySingletonesRegistry.sol';
import "./UpgradabilityStorage.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {

    /**
    * @dev Constructor function
    */
    constructor (string _version) public {
        registry = ITwoKeySingletonesRegistry(msg.sender);
        upgradeTo(_version);
    }

    /**
    * @dev Upgrades the implementation to the requested version
    * @param _version representing the version name of the new implementation to be set
    */
    function upgradeTo(string _version) public {
        _implementation = registry.getVersion(_version);
    }

}