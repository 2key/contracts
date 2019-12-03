pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaFactoryStorage.sol";
import "../interfaces/IHandleCampaignDeploymentPlasma.sol";
import "../upgradable-pattern-campaigns/ProxyCampaign.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyPlasmaFactory is Upgradeable {

    bool initialized;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _addressToCampaignType = "addressToCampaignType";
    string public test;
    address public test_address;
    ITwoKeyPlasmaFactoryStorage PROXY_STORAGE_CONTRACT;

    event ProxyForCPCCampaign(
        address proxyCampaign,
        address contractorPlasmas
    );

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
        string _url
    )
    public
    {
        address proxyPlasmaCPC = createProxyForCampaign("CPC_PLASMA", "TwoKeyCPCCampaignPlasma");
        test = "DEPLOYED_PROXY";
        test_address = proxyPlasmaCPC;
        IHandleCampaignDeploymentPlasma(proxyPlasmaCPC).setInitialParamsCPCCampaignPlasma(
            TWO_KEY_PLASMA_SINGLETON_REGISTRY,
            msg.sender,
            _url
        );
//
//        setAddressToCampaignType(proxyPlasmaCPC, "CPC_PLASMA");
        emit ProxyForCPCCampaign(proxyPlasmaCPC, msg.sender);
    }


    /**
     * @notice internal function to set address to campaign type
     * @param _campaignAddress is the address of campaign
     * @param _campaignType is the type of campaign (String)
     */
    function setAddressToCampaignType(address _campaignAddress, string _campaignType) internal {
        bytes32 keyHash = keccak256(_addressToCampaignType, _campaignAddress);
        PROXY_STORAGE_CONTRACT.setString(keyHash, _campaignType);
    }

    /**
     * @notice Function working as a getter
     * @param _key is the address of campaign
     */
    function addressToCampaignType(address _key) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToCampaignType, _key));
    }



}
