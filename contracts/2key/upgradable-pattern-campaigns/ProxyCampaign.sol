pragma solidity ^0.4.24;


import "./UpgradabilityCampaignStorage.sol";
import "../upgradability/Proxy.sol";


contract ProxyCampaign is Proxy, UpgradeabilityCampaignStorage {

    constructor (string _contractName, string _version, address twoKeySingletonRegistry) public {
        _implementation = ITwoKeySingletonesRegistry(twoKeySingletonRegistry).getVersion(_contractName, _version);
    }
}
