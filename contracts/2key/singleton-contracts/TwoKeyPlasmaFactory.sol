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


    function getLatestApprovedCampaignVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getLatestCampaignApprovedVersion(campaignType);
    }


    function createProxyForCampaign(
        string campaignType,
        string campaignName
    )
    internal
    returns (address)
    {
        ProxyCampaign proxy = new ProxyCampaign(
            campaignName,
            getLatestApprovedCampaignVersion(campaignType),
            address(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        );

        return address(proxy);
    }

    function createPlasmaCPCCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        address proxyPlasmaCPC = createProxyForCampaign("CPC_PLASMA", "TwoKeyCPCCampaignPlasma");

        IHandleCampaignDeploymentPlasma(proxyPlasmaCPC).setInitialParamsCPCCampaignPlasma(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );

        setCampaignToNonSingletonHash(proxyPlasmaCPC, _nonSingletonHash);
        setCampaignCreatedThroughFactory(proxyPlasmaCPC);
        setAddressToCampaignType(proxyPlasmaCPC, "CPC_PLASMA");
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(proxyPlasmaCPC, msg.sender);
    }

    function createPlasmaCPCNoRewardsCampaign(
        string _url,
        uint[] numberValuesArray,
        string _nonSingletonHash
    )
    public
    {
        address proxyPlasmaCPCNoRewards = createProxyForCampaign("CPC_NO_REWARDS_PLASMA","TwoKeyCPCCampaignPlasmaNoReward");

        IHandleCampaignDeploymentPlasma(proxyPlasmaCPCNoRewards).setInitialParamsCPCCampaignPlasmaNoRewards(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url,
            numberValuesArray
        );

        setCampaignToNonSingletonHash(proxyPlasmaCPCNoRewards, _nonSingletonHash);
        setCampaignCreatedThroughFactory(proxyPlasmaCPCNoRewards);
        setAddressToCampaignType(proxyPlasmaCPCNoRewards, "CPC_NO_REWARDS_PLASMA");
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitCPCCampaignCreatedEvent(proxyPlasmaCPCNoRewards, msg.sender);
    }

    /**
     * @notice          For PPC campaigns we store their non singleton hash
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
     * @notice Internal function which will set that campaign is created through the factory
     * and whitelist that address
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
     * @notice internal function to set address to campaign type
     * @param _campaignAddress is the address of campaign
     * @param _campaignType is the type of campaign (String)
     */
    function setAddressToCampaignType(address _campaignAddress, string _campaignType) internal {
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToCampaignType, _campaignAddress), _campaignType);
    }

    /**
     * @notice Function working as a getter
     * @param _key is the address of campaign
     */
    function addressToCampaignType(address _key) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToCampaignType, _key));
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

}
