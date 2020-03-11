pragma solidity ^0.4.24;


import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../upgradable-pattern-campaigns/ProxyCampaign.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyFactoryStorage.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";


/**
 * @author Nikola Madjarevic
 * @notice Contract to deploy all contracts
 */
contract TwoKeyFactory is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    string constant _addressToCampaignType = "addressToCampaignType";
    string constant _twoKeyEventSource = "TwoKeyEventSource";
    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";

    ITwoKeyFactoryStorage PROXY_STORAGE_CONTRACT;

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
        address proxyDonationLogicHandler,
        address contractor
    );


    /**
     * @notice Function to set initial parameters for the contract
     * @param _twoKeySingletonRegistry is the address of singleton registry contract
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonRegistry);
        PROXY_STORAGE_CONTRACT = ITwoKeyFactoryStorage(_proxyStorage);
        initialized = true;
    }

    function getLatestApprovedCampaignVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
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
            address(TWO_KEY_SINGLETON_REGISTRY)
        );
        return address(proxy);
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
        address proxyAcquisition = createProxyForCampaign("TOKEN_SELL","TwoKeyAcquisitionCampaignERC20");

        //Deploy proxy for ConversionHandler contract
        address proxyConversions = createProxyForCampaign("TOKEN_SELL","TwoKeyConversionHandler");

        //Deploy proxy for TwoKeyAcquisitionLogicHandler contract
        address proxyLogicHandler = createProxyForCampaign("TOKEN_SELL","TwoKeyAcquisitionLogicHandler");

        //Deploy proxy for TwoKeyPurchasesHandler contract
        address proxyPurchasesHandler = createProxyForCampaign("TOKEN_SELL","TwoKeyPurchasesHandler");


        IHandleCampaignDeployment(proxyPurchasesHandler).setInitialParamsPurchasesHandler(
            valuesConversion,
            msg.sender,
            addresses[0],
            getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource),
            proxyConversions
        );

        // Set initial arguments inside Conversion Handler contract
        IHandleCampaignDeployment(proxyConversions).setInitialParamsConversionHandler(
            valuesConversion,
            proxyAcquisition,
            proxyPurchasesHandler,
            msg.sender,
            addresses[0], //ERC20 address
            TWO_KEY_SINGLETON_REGISTRY
        );

        // Set initial arguments inside Logic Handler contract
        IHandleCampaignDeployment(proxyLogicHandler).setInitialParamsLogicHandler(
            valuesLogicHandler,
            _currency,
            addresses[0], //asset contract erc20
            addresses[1], // moderator
            msg.sender,
            proxyAcquisition,
            address(TWO_KEY_SINGLETON_REGISTRY),
            proxyConversions
        );

        // Set initial arguments inside AcquisitionCampaign contract
        IHandleCampaignDeployment(proxyAcquisition).setInitialParamsCampaign(
            address(TWO_KEY_SINGLETON_REGISTRY),
            address(proxyLogicHandler),
            address(proxyConversions),
            addresses[1], //moderator
            addresses[0], //asset contract
            msg.sender, //contractor
            getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"),
            values
        );

        // Validate campaign so it will be approved to interact (and write) to/with our singleton contracts
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateAcquisitionCampaign(proxyAcquisition, _nonSingletonHash);

        setAddressToCampaignType(proxyAcquisition, "TOKEN_SELL");

        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .acquisitionCampaignCreated(
            proxyLogicHandler,
            proxyConversions,
            proxyAcquisition,
            proxyPurchasesHandler,
            plasmaOf(msg.sender)
        );
    }


    /**
     * @notice Function to deploy proxy contracts for donation campaigns
     */
    function createProxiesForDonationCampaign(
        address _moderator,
        uint [] numberValues,
        bool [] booleanValues,
        string _currency,
        string tokenName,
        string tokenSymbol,
        string nonSingletonHash
    )
    public
    {

        // Deploying a proxy contract for donations
        address proxyDonationCampaign = createProxyForCampaign("DONATION","TwoKeyDonationCampaign");

        //Deploying a proxy contract for donation conversion handler
        address proxyDonationConversionHandler = createProxyForCampaign("DONATION","TwoKeyDonationConversionHandler");

        //Deploying a proxy contract for donation logic handler
        address proxyDonationLogicHandler = createProxyForCampaign("DONATION","TwoKeyDonationLogicHandler");

        IHandleCampaignDeployment(proxyDonationLogicHandler).setInitialParamsDonationLogicHandler(
            numberValues,
            _currency,
            msg.sender,
            _moderator,
            TWO_KEY_SINGLETON_REGISTRY,
            proxyDonationCampaign,
            proxyDonationConversionHandler
        );

        // Set initial parameters under Donation conversion handler
        IHandleCampaignDeployment(proxyDonationConversionHandler).setInitialParamsDonationConversionHandler(
            tokenName,
            tokenSymbol,
            _currency,
            msg.sender, //contractor
            proxyDonationCampaign,
            address(TWO_KEY_SINGLETON_REGISTRY)
        );
//
        // Set initial parameters under Donation campaign contract
        IHandleCampaignDeployment(proxyDonationCampaign).setInitialParamsDonationCampaign(
            msg.sender, //contractor
            _moderator, //moderator address
            TWO_KEY_SINGLETON_REGISTRY,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            numberValues,
            booleanValues
        );

        // Validate campaign
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateDonationCampaign(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            nonSingletonHash
        );

        setAddressToCampaignType(proxyDonationCampaign, "DONATION");

        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .donationCampaignCreated(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            plasmaOf(msg.sender)
        );
    }

    function createProxyForCPCCampaign(
        string _url,
        uint _bountyPerConversion,
        address _mirrorCampaignOnPlasma,
        string _nonSingletonHash
    )
    public
    {
        address proxyCPC = createProxyForCampaign("CPC_PUBLIC","TwoKeyCPCCampaign");

        IHandleCampaignDeployment(proxyCPC).setInitialParamsCPCCampaign(
            msg.sender,
            TWO_KEY_SINGLETON_REGISTRY,
            _url,
            _mirrorCampaignOnPlasma,
            _bountyPerConversion,
            getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")
        );

        setAddressToCampaignType(proxyCPC, "CPC_PUBLIC");

        //Validate campaign
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateCPCCampaign(
            proxyCPC,
            _nonSingletonHash
        );

        //Emit event that TwoKeyCPCCampaign contract is created
        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .cpcCampaignCreated(
            proxyCPC,
            plasmaOf(msg.sender)
        );
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

    function plasmaOf(address _address) internal view returns (address) {
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
        address plasma = ITwoKeyEventSourceEvents(twoKeyEventSource).plasmaOf(_address);
        return plasma;
    }



}
