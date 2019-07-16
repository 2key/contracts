pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletonesRegistry.sol";

/**
 * @title UpgradeabilityStorage
 */
contract UpgradeabilityCampaignStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    address internal twoKeyFactory;

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
