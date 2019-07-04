pragma solidity ^0.4.24;

import '../interfaces/ITwoKeySingletonesRegistry.sol';

/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    // Address internal deployer
    address internal _deployer;


    function deployer() public view returns (address) {
        return _deployer;
    }
    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}
