pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaFactoryStorage.sol";
import "../interfaces/IHandleCampaignDeploymentPlasma.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../upgradable-pattern-campaigns/ProxyCampaign.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyPlasmaFactory is Upgradeable {

    bool initialized;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _addressToCampaignType = "addressToCampaignType";
    string constant _isCampaignCreatedThroughFactory = "isCampaignCreatedThroughFactory";
    string constant _campaignAddressToNonSingletonHash = "campaignAddressToNonSingletonHash";

    ITwoKeyPlasmaFactoryStorage PROXY_STORAGE_CONTRACT;


    /**
     * @notice          Function to set initial params once proxy is created. Called only once
     * @param           _twoKeyPlasmaSingletonRegistry is address of TwoKeyPlasmaSingletonRegistry contract
     *                  That contract is used as a single service providing addresses of all other contracts
     * @param           _proxyStorage is proxy address of storage contract. That address will be never changed.
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaFactoryStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice          Function to get address of some contract registered in TwoKeySingletonRegistry
     * @param           contractName is the name of the contract which address is being requested.
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }


    /**
     * @notice Internal function which will set that campaign is created through the factory
     * and whitelist that address. Used in a scope of campaign creation
     * @param _campaignAddress is the campaign we want to set this rule
     */
    function setCampaignCreatedThroughFactory(
        address _campaignAddress
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignCreatedThroughFactory, _campaignAddress), true);
    }


    /**
     * @notice Internal function to set address to campaign type. Used in scope of campaign creation
     * @param _campaignAddress is the address of campaign
     * @param _campaignType is the type of campaign (String)
     */
    function setAddressToCampaignType(
        address _campaignAddress,
        string _campaignType
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToCampaignType, _campaignAddress), _campaignType);
    }


    /**
     * @notice          For every campaign type, we store during creation which non-singleton
     *                  hash was active at that moment.
     * @param           _campaignAddress is the address of campaign
     * @param           _nonSingletonHash is the non singleton hash
     */
    function setCampaignToNonSingletonHash(
        address _campaignAddress,
        string _nonSingletonHash
    )
    internal
    {
        bytes32 key = keccak256(_campaignAddressToNonSingletonHash,_campaignAddress);
        PROXY_STORAGE_CONTRACT.setString(key, _nonSingletonHash);
    }


    /**
     * @notice          Function to store basic accounting information when campaign
     *                  is being created.
     * @param           campaignProxy is proxy address for campaign being deployed
     * @param           nonSingletonHash is the non singleton hash active at the moment
     * @param           campaignType is the type of the campaign being deployed
     */
    function storeBasicProxyInformation(
        address campaignProxy,
        string nonSingletonHash,
        string campaignType
    )
    internal
    {
        // Set campaign to non singleton hash
        setCampaignToNonSingletonHash(campaignProxy, nonSingletonHash);
        // Mark that campaign is created through the factory
        setCampaignCreatedThroughFactory(campaignProxy);
        // Set campaign to campaign type
        setAddressToCampaignType(campaignProxy, campaignType);
    }


    /**
     * @notice          Internal function used in processing of campaign creation
     * @param           campaignType is the type of campaign being created
     * @param           contractName is the name of the contract which should be deployed.
     */
    function createProxyForCampaign(
        string campaignType,
        string contractName
    )
    internal
    returns (address)
    {
        ProxyCampaign proxy = new ProxyCampaign(
            contractName,
            getLatestApprovedCampaignVersion(campaignType),
            TWO_KEY_PLASMA_SINGLETON_REGISTRY
        );

        return address(proxy);
    }


    /**
     * @notice          Function to check latest approved version of the
     *                  campaign type
     * @param           campaignType is the type of the campaign we are requesting latest version
     */
    function getLatestApprovedCampaignVersion(
        string campaignType
    )
    internal
    view
    returns (string)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getLatestCampaignApprovedVersion(campaignType);
    }


    /**
     * @notice          Function to create CPC campaign contract.
     * @param           _url is the url which is converted to smartlink
     * @param           numberValuesArray is the array of values which should be set
     *                  on the campaign contract
     * @param           _nonSingletonHash is the hash of non-singleton contracts, active
     *                  at the moment of campaign creation
     */
    function createPlasmaCPCCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        // Create proxy
        address campaignProxy = createProxyForCampaign("CPC_PLASMA", "TwoKeyCPCCampaignPlasma");
        // Call "constructor" on proxy
        IHandleCampaignDeploymentPlasma(campaignProxy).setInitialParamsCPCCampaignPlasma(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );
        // Store basic accounting information for the proxy
        storeBasicProxyInformation(campaignProxy, _nonSingletonHash, "CPC_PLASMA");
        // Emit event in TwoKeyPlasmaEventSource
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(campaignProxy, msg.sender);
    }


    /**
     * @notice          Function to create CPC NO REWARDS campaign contract.
     * @param           _url is the url which is converted to smartlink
     * @param           numberValuesArray is the array of values which should be set
     *                  on the campaign contract
     * @param           _nonSingletonHash is the hash of non-singleton contracts, active
     *                  at the moment of campaign creation
     */
    function createPlasmaCPCNoRewardsCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        // Create proxy
        address campaignProxy = createProxyForCampaign("CPC_NO_REWARDS_PLASMA","TwoKeyCPCCampaignPlasmaNoReward");
        // Call "constructor" on proxy
        IHandleCampaignDeploymentPlasma(campaignProxy).setInitialParamsCPCCampaignPlasmaNoRewards(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );
        // Store basic accounting information for the proxy
        storeBasicProxyInformation(campaignProxy, _nonSingletonHash, "CPC_NO_REWARDS_PLASMA");
        // Emit event in TwoKeyPlasmaEventSource
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(campaignProxy, msg.sender);
    }


    /**
     * @notice          Function to create AFFILIATION campaign contract.
     * @param           _url is the url where conversion is happening
     * @param           numberValuesArray is the array of values which should be set
     *                  on the campaign contract
     * @param           _nonSingletonHash is the hash of non-singleton contracts, active
     *                  at the moment of campaign creation
     */
    function createPlasmaAffiliationCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        // Create proxy
        address campaignProxy = createProxyForCampaign("AFFILIATION_PLASMA", "TwoKeyPlasmaAffiliationCampaign");
        // Call "constructor" on proxy
        IHandleCampaignDeploymentPlasma(campaignProxy).setInitialParamsAffiliationCampaignPlasma(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );
        // Store basic accounting information for the proxy
        storeBasicProxyInformation(campaignProxy, _nonSingletonHash, "AFFILIATION_PLASMA");
        // Emit event in TwoKeyPlasmaEventSource
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitAffiliationCampaignCreated(campaignProxy, msg.sender);
    }


    /**
     * @notice Getter to check if the campaign is created through TwoKeyPlasmaFactory
     * which will whitelist it to emit all the events through TwoKeyPlasmaEvents
     * @param _campaignAddress is the address of the campaign we want to check
     */
    function isCampaignCreatedThroughFactory(
        address _campaignAddress
    )
    public
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(keccak256(_isCampaignCreatedThroughFactory, _campaignAddress));
    }


    /**
     * @notice          Getter to return the non singleton hash assigned to campaign
     * @param           campaignAddress is the address of campaign
     */
    function getNonSingletonHashForCampaign(
        address campaignAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_campaignAddressToNonSingletonHash, campaignAddress));
    }


    /**
     * @notice          Function returning for specified address which campaign type it is
     * @param           _campaignAddress is address of requested campaign
     */
    function addressToCampaignType(
        address _campaignAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToCampaignType, _key));
    }
}
