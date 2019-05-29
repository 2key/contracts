pragma solidity ^0.4.24;

import '../Upgradeable.sol';
import "../UpgradabilityProxy.sol";
import "../TwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletonesRegistry.sol";

/**
 * @author Nikola Madjarevic
 * @title Registry for plasma network
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 * @notice Will be everything mapped by contract name, so we will easily update and get versions per contract, all stored here
 */
contract TwoKeyPlasmaSingletoneRegistry is ITwoKeySingletonesRegistry {

    mapping(address => bool) public isMaintainer;

    mapping (string => mapping(string => address)) internal versions;
    mapping (string => address) contractToProxy;
    mapping (string => string) contractNameToLatestVersionName;


    constructor(address [] _maintainers, address _twoKeyAdmin) public {
        isMaintainer[msg.sender] = true; //for truffle deployment
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    modifier onlyMaintainer {
        require(isMaintainer[msg.sender]);
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

    /**
     * @dev Creates an upgradeable proxy
     * @param version representing the first version to be set for the proxy
     * @return address of the new proxy created
     */
    function createProxy(string contractName, string version) public onlyMaintainer payable returns (UpgradeabilityProxy) {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version, msg.sender);
        Upgradeable(proxy).initialize.value(msg.value)(msg.sender);
        contractToProxy[contractName] = proxy;
        emit ProxyCreated(proxy);
        return proxy;
    }

    function addMaintainers(
        address [] _maintainers
    )
    public
    onlyMaintainer
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(
        address [] _maintainers
    )
    public
    onlyMaintainer
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }
}
