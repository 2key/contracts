pragma solidity ^0.4.0;

import "../Upgradeable.sol";
import "../MaintainingPattern.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../upgradable-pattern-campaigns/ProxyCampaign.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../acquisition-campaign-contracts/TwoKeyPurchasesHandler.sol";
import "../acquisition-campaign-contracts/TwoKeyAcquisitionLogicHandler.sol";


/**
 * @author Nikola Madjarevic
 * @title Contract used to deploy proxies for other non-singleton contracts
 */
contract TwoKeyFactory is Upgradeable, MaintainingPattern {

    //Address of singleton registry
    ITwoKeySingletoneRegistryFetchAddress public twoKeySingletonRegistry;

    event ProxyForCampaign(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    );

    event ProxyForDonationCampaign(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address contractor
    );

    address public moderator;

    /**
     * @notice Function to set initial parameters for the contract
     * @param _twoKeySingletonRegistry is the address of singleton registry contract
     * @param _twoKeyAdmin is the address if twoKeyAdmin contract
     * @param _maintainers is the array of maintainers
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _twoKeyAdmin,
        address [] _maintainers
    )
    public
    {
        require(twoKeySingletonRegistry == address(0));

        twoKeyAdmin = _twoKeyAdmin;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }

        twoKeySingletonRegistry = ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonRegistry);
    }

    function getContractProxyAddress(string contractName) internal view returns (address) {
        return twoKeySingletonRegistry.getContractProxyAddress(contractName);
    }

    /**
     * @notice Function used to deploy all necessary proxy contracts in order to use the campaign.
     * @dev This function will handle all necessary actions which should be done on the contract
     * in order to make them ready to work. Also, we've been unfortunately forced to use arrays
     * as arguments since the stack is not deep enough to handle this amount of input information
     * since this method handles kick-start of 3 contracts
     * @param addresses is array of addresses needed [assetContractERC20,moderator]
     * @param valuesConversion is array containing necessary values to start conversion handler contract
     * @param valuesLogicHandler is array of values necessary to start logic handler contract
     * @param values is array containing values necessary to start campaign contract
     * @param _currency is the main currency token price is set
     * @param _nonSingletonHash is the hash of non-singleton contracts active with responding
     * 2key-protocol version at the moment
     */
    function createProxiesForAcquisitions(
        address[] addresses,
        uint[] valuesConversion,
        uint[] valuesLogicHandler,
        uint[] values,
        string _currency,
        string _nonSingletonHash
    )
    public
    payable
    {
        //Deploy proxy for Acquisition contract
        ProxyCampaign proxyAcquisition = new ProxyCampaign(
            "TwoKeyAcquisitionCampaignERC20",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyAcquisitionCampaignERC20"),
            address(twoKeySingletonRegistry)
        );

        //Deploy proxy for ConversionHandler contract
        ProxyCampaign proxyConversions = new ProxyCampaign(
            "TwoKeyConversionHandler",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyConversionHandler"),
            address(twoKeySingletonRegistry)
        );

        //Deploy proxy for TwoKeyAcquisitionLogicHandler contract
        ProxyCampaign proxyLogicHandler = new ProxyCampaign(
            "TwoKeyAcquisitionLogicHandler",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyAcquisitionLogicHandler"),
            address(twoKeySingletonRegistry)
        );


        //Deploy proxy for TwoKeyPurchasesHandler contract
        ProxyCampaign proxyPurchasesHandler = new ProxyCampaign(
            "TwoKeyPurchasesHandler",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyAcquisitionLogicHandler"),
            address(twoKeySingletonRegistry)
        );


        //        UpgradeableCampaign(proxyPurchasesHandler).initialize.value(msg.value)(msg.sender);
        //        UpgradeableCampaign(proxyLogicHandler).initialize.value(msg.value)(msg.sender);
        //        UpgradeableCampaign(proxyConversions).initialize.value(msg.value)(msg.sender);
        //        UpgradeableCampaign(proxyAcquisition).initialize.value(msg.value)(msg.sender);

        IHandleCampaignDeployment(proxyPurchasesHandler).setInitialParamsPurchasesHandler(
            valuesConversion,
            msg.sender,
            addresses[0],
            getContractProxyAddress("TwoKeyEventSource"),
            proxyConversions
        );

        // Set initial arguments inside Conversion Handler contract
        IHandleCampaignDeployment(proxyConversions).setInitialParamsConversionHandler(
            valuesConversion,
            proxyAcquisition,
            proxyPurchasesHandler,
            msg.sender,
            addresses[0], //ERC20 address
            getContractProxyAddress("TwoKeyEventSource"),
            getContractProxyAddress("TwoKeyBaseReputationRegistry")
        );

        // Set initial arguments inside Logic Handler contract
        IHandleCampaignDeployment(proxyLogicHandler).setInitialParamsLogicHandler(
            valuesLogicHandler,
            _currency,
            addresses[0], //asset contract erc20
            addresses[1], // moderator
            msg.sender,
            proxyAcquisition,
            address(twoKeySingletonRegistry),
            proxyConversions
        );

        // Set initial arguments inside AcquisitionCampaign contract
        IHandleCampaignDeployment(proxyAcquisition).setInitialParamsCampaign(
            address(twoKeySingletonRegistry),
            address(proxyLogicHandler),
            address(proxyConversions),
            addresses[1], //moderator
            addresses[0], //asset contract
            msg.sender, //contractor
            values
        );

        // Validate campaign so it will be approved to interact (and write) to/with our singleton contracts
        ITwoKeyCampaignValidator(getContractProxyAddress("TwoKeyCampaignValidator"))
        .validateAcquisitionCampaign(proxyAcquisition, _nonSingletonHash);

        // Emit an event with proxies for Acquisition campaign
        emit ProxyForCampaign(
            proxyLogicHandler,
            proxyConversions,
            proxyAcquisition,
            proxyPurchasesHandler,
            msg.sender
        );
    }


    /**
     * @notice Function to deploy proxy contracts for donation campaigns
     */
    function createProxiesForDonationCampaign(
        address _moderator,
        uint [] numberValues,
        bool [] booleanValues,
        string _campaignName,
        string tokenName,
        string tokenSymbol,
        string nonSingletonHash
    )
    public
    {

        moderator = _moderator;

        // Deploying a proxy contract for donations
        ProxyCampaign proxyDonationCampaign = new ProxyCampaign(
            "TwoKeyDonationCampaign",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyDonationCampaign"),
            address(twoKeySingletonRegistry)
        );

        //Deploying a proxy contract for donation conversion handler
        ProxyCampaign proxyDonationConversionHandler = new ProxyCampaign(
            "TwoKeyDonationConversionHandler",
            twoKeySingletonRegistry.getLatestContractVersion("TwoKeyDonationConversionHandler"),
            address(twoKeySingletonRegistry)
        );

        // Set initial parameters under Donation conversion handler
        IHandleCampaignDeployment(proxyDonationConversionHandler).setInitialParamsDonationConversionHandler(
            tokenName,
            tokenSymbol,
            msg.sender, //contractor
            proxyDonationCampaign,
            booleanValues[1],
            numberValues[0]
        );

        // Set initial parameters under Donation campaign contract
        IHandleCampaignDeployment(proxyDonationCampaign).setInitialParamsDonationCampaign(
            msg.sender, //contractor
            _moderator, //moderator address
            address(twoKeySingletonRegistry),
            proxyDonationConversionHandler,
            numberValues,
            booleanValues,
            _campaignName
        );

        // Validate campaign
        ITwoKeyCampaignValidator(getContractProxyAddress("TwoKeyCampaignValidator"))
        .validateDonationCampaign(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            nonSingletonHash
        );

//         Emit an event
        emit ProxyForDonationCampaign(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            msg.sender
        );

    }

}
