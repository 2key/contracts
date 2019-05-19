pragma solidity ^0.4.0;


import "./Proxy.sol";
import "./UpgradabilityStorage.sol";


contract UpgradabilityProxyAcquisition is Proxy, UpgradeabilityStorage {

    constructor (string _contractName, string _version) public {
        registry = ITwoKeySingletonesRegistry(msg.sender);
        _implementation = registry.getVersion(_contractName, _version);
    }
}
