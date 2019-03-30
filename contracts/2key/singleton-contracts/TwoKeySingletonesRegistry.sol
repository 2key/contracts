pragma solidity ^0.4.24;

import '../Upgradeable.sol';
import "../UpgradabilityProxy.sol";
import "../MaintainingPattern.sol";

import '../interfaces/ITwoKeySingletonesRegistry.sol';
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";


/**
 * @author Nikola Madjarevic
 * @title Registry
 * @dev This contract works as a registry of versions, it holds the implementations for the registered versions.
 * @notice Will be everything mapped by contract name, so we will easily update and get versions per contract, all stored here
 */
contract TwoKeySingletonesRegistry is MaintainingPattern, ITwoKeySingletonesRegistry {

    mapping (string => mapping(string => address)) internal versions;
    mapping (string => mapping(string => address)) internal campaignVersions;


    mapping (string => address) contractToProxy;
    mapping (string => string) contractNameToLatestVersionName;
    mapping (string => address) nonUpgradableContractToAddress;

    address[] allVerified2keyContracts;

    struct UserCampaigns{
        address [] acquisitionCampaigns;
        address [] acquisitionLogicHandlers;
        address [] acquisitionConversionHandlers;
    }

    mapping(address => UserCampaigns) user2campaigns;

    /**
     * @notice Calling super constructor from maintaining pattern
     */
    constructor(address [] _maintainers, address _twoKeyAdmin) public {
        twoKeyAdmin = _twoKeyAdmin;
        isMaintainer[msg.sender] = true; //for truffle deployment
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function to add non upgradable contract in registry of all contracts
     * @param contractName is the name of the contract
     * @param contractAddress is the contract address
     * @dev only maintainer can issue call to this method
     */
    function addNonUpgradableContractToAddress(string contractName, address contractAddress) public onlyMaintainer {
        nonUpgradableContractToAddress[contractName] = contractAddress;
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


    //TODO: Create separate method and storage to handle acquisition campaign deployments , versions, etc
    // Because we can't mess up with versions especially since they're going to be maybe upgradable upon a handshake
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


    function getNonUpgradableContractAddress(string contractName) public view returns (address) {
        return nonUpgradableContractToAddress[contractName];
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

    function createProxiesForAcquisitions(
        address[] addresses,
        uint[] values_conversion,
        uint[] values_logic_handler,
        uint[] values,
        string _currency,
        string _nonSingletonHash
    ) public payable {
        // Deploy proxies for all 3 contracts
        UpgradeabilityProxy proxyAcquisition = new UpgradeabilityProxy("TwoKeyAcquisitionCampaignERC20", "1.0");
        Upgradeable(proxyAcquisition).initialize.value(msg.value)(msg.sender);

        UpgradeabilityProxy proxyConversions = new UpgradeabilityProxy("TwoKeyConversionHandler", "1.0");
        Upgradeable(proxyConversions).initialize.value(msg.value)(msg.sender);

        UpgradeabilityProxy proxyLogicHandler = new UpgradeabilityProxy("TwoKeyAcquisitionLogicHandler", "1.0");
        Upgradeable(proxyLogicHandler).initialize.value(msg.value)(msg.sender);


        // Set initial arguments inside Conversion Handler contract
        IHandleCampaignDeployment(proxyConversions).setInitialParamsConversionHandler(
            values_conversion,
            proxyAcquisition,
            msg.sender,
            addresses[0], //ERC20 address
            getContractProxyAddress("TwoKeyEventSource"),
            getContractProxyAddress("TwoKeyBaseReputationRegistry")
        );

        // Set initial arguments inside Logic Handler contract
        IHandleCampaignDeployment(proxyLogicHandler).setInitialParamsLogicHandler(
            values_logic_handler,
            _currency,
            addresses[0], //asset contract erc20
            addresses[1], // moderator
            msg.sender,
            proxyAcquisition,
            address(this),
            proxyConversions
        );

        // Set initial arguments inside AcquisitionCampaign contract
        IHandleCampaignDeployment(proxyAcquisition).setInitialParamsCampaign(
            address(this),
            address(proxyLogicHandler),
            address(proxyConversions),
            addresses[1], //moderator
            addresses[0], //asset contract
            msg.sender, //contractor
            values
        );

        ITwoKeyCampaignValidator(getContractProxyAddress("TwoKeyCampaignValidator"))
            .validateAcquisitionCampaign(proxyAcquisition, _nonSingletonHash);

        emit ProxyForCampaign(proxyLogicHandler, proxyConversions, proxyAcquisition);
    }


    /**
     * @notice Function to return all 2key running contract addresses
     * @return array with all contract addresses
     */
    function getAll2keyContracts() public view returns (address[]) {
        return allVerified2keyContracts;
    }
}
