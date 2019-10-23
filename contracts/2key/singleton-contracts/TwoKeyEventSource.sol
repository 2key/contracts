pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyEventSourceStorage.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";


contract TwoKeyEventSource is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    ITwoKeyEventSourceStorage public PROXY_STORAGE_CONTRACT;

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    /**
     * Modifier which will allow only TwoKeyCampaignValidator to make some calls
     */
    modifier onlyTwoKeyCampaignValidator {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(msg.sender == twoKeyCampaignValidator);
        _;
    }

    /**
     * @notice Function to set initial params in the contract
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyEventSourceStorage(_proxyStorage);

        initialized = true;
    }


    event Created(
        address _campaign,
        address _owner,
        address _moderator
    );

    event Joined(
        address _campaign,
        address _from,
        address _to
    );

    event Converted(
        address _campaign,
        address _converter,
        uint256 _amount
    );

    // TODO: DEPRECATED IN NEW DEPLOYMENT
    event ConvertedAcquisition(
        address _campaign,
        address _converter,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion
    );


    event ConvertedAcquisitionV2(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    );

    // TODO: DEPRECATED
    event ConvertedDonation(
        address _campaign,
        address _converter,
        uint _conversionAmount
    );

    event ConvertedDonationV2(
        address _campaign,
        address _converterPlasma,
        uint _conversionAmount,
        uint _conversionId
    );

    event Rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    );

    event Cancelled(
        address _campaign,
        address _converter,
        uint256 _indexOrAmount
    );

    event Rejected(
        address _campaign,
        address _converter
    );

    event UpdatedPublicMetaHash(
        uint timestamp,
        string value
    );

    event UpdatedData(
        uint timestamp,
        uint value,
        string action
    );

    event ReceivedEther(
        address _sender,
        uint value
    );

    event AcquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    );

    event DonationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    );

    event PriceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    );

    event UserRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    );

    event Executed(
        address campaignAddress,
        address converterPlasmaAddress,
        uint conversionId
    );

    event ExecutedV1(
        address campaignAddress,
        address converterPlasmaAddress,
        uint conversionId,
        uint tokens
    );

    /**
     * @notice Function to emit created event every time campaign is created
     * @param _campaign is the address of the deployed campaign
     * @param _owner is the contractor address of the campaign
     * @param _moderator is the address of the moderator in campaign
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external
    onlyTwoKeyCampaignValidator
    {
        emit Created(_campaign, _owner, _moderator);
    }

    /**
     * @notice Function to emit created event every time someone has joined to campaign
     * @param _campaign is the address of the deployed campaign
     * @param _from is the address of the referrer
     * @param _to is the address of person who has joined
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function joined(
        address _campaign,
        address _from,
        address _to
    )
    external
    onlyAllowedContracts
    {
        emit Joined(_campaign, _from, _to);
    }

    /**
     * @notice Function to emit converted event
     * @param _campaign is the address of main campaign contract
     * @param _converter is the address of converter during the conversion
     * @param _conversionAmount is conversion amount
     */
    function converted(
        address _campaign,
        address _converter,
        uint256 _conversionAmount
    )
    external
    onlyAllowedContracts
    {
        emit Converted(_campaign, _converter, _conversionAmount);
    }

    function rejected(
        address _campaign,
        address _converter
    )
    external
    onlyAllowedContracts
    {
        emit Rejected(_campaign, _converter);
    }

    /**
     * @notice Function to emit event every time conversion gets executed
     * @param _campaignAddress is the main campaign contract address
     * @param _converterPlasmaAddress is the address of converter plasma
     * @param _conversionId is the ID of conversion, unique per campaign
     */
    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit Executed(_campaignAddress, _converterPlasmaAddress, _conversionId);
    }

    /**
     * @notice Function to emit event every time conversion gets executed
     * @param _campaignAddress is the main campaign contract address
     * @param _converterPlasmaAddress is the address of converter plasma
     * @param _conversionId is the ID of conversion, unique per campaign
     */
    function executedV1(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external
    onlyAllowedContracts
    {
        emit ExecutedV1(_campaignAddress, _converterPlasmaAddress, _conversionId, tokens);
    }

    //TODO: DEPRECATED FOR NEW CAMPAIGNS
    function convertedAcquisition(
        address _campaign,
        address _converter,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedAcquisition(_campaign, _converter, _baseTokens, _bonusTokens, _conversionAmount, _isFiatConversion);
    }


    /**
     * @notice Function to emit created event every time conversion happened under AcquisitionCampaign
     * @param _campaign is the address of the deployed campaign
     * @param _converterPlasma is the converter address
     * @param _baseTokens is the amount of tokens bought
     * @param _bonusTokens is the amount of bonus tokens received
     * @param _conversionAmount is the amount of conversion
     * @param _isFiatConversion is flag representing if conversion is either FIAT or ETHER
     * @param _conversionId is the id of conversion
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function convertedAcquisitionV2(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedAcquisitionV2(_campaign, _converterPlasma, _baseTokens, _bonusTokens, _conversionAmount, _isFiatConversion, _conversionId);
    }


    function convertedDonation(
        address _campaign,
        address _converter,
        uint256 _conversionAmount
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedDonation(_campaign, _converter, _conversionAmount);
    }


    /**
     * @notice Function to emit created event every time conversion happened under DonationCampaign
     * @param _campaign is the address of main campaign contract
     * @param _converterPlasma is the address of the converter
     * @param _conversionAmount is the amount of conversion
     * @param _conversionId is the id of conversion
     */
    function convertedDonationV2(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedDonationV2(_campaign, _converterPlasma, _conversionAmount, _conversionId);
    }

    /**
     * @notice Function to emit created event every time bounty is distributed between influencers
     * @param _campaign is the address of the deployed campaign
     * @param _to is the reward receiver
     * @param _amount is the reward amount
     */
    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external
    onlyAllowedContracts
    {
        emit Rewarded(_campaign, _to, _amount);
    }

    /**
     * @notice Function to emit created event every time campaign is cancelled
     * @param _campaign is the address of the cancelled campaign
     * @param _converter is the address of the converter
     * @param _indexOrAmount is the amount of campaign
     */
    function cancelled(
        address  _campaign,
        address _converter,
        uint256 _indexOrAmount
    )
    external
    onlyAllowedContracts
    {
        emit Cancelled(_campaign, _converter, _indexOrAmount);
    }

    /**
     * @notice Function to emit event every time someone starts new Acquisition campaign
     * @param proxyLogicHandler is the address of TwoKeyAcquisitionLogicHandler proxy deployed by TwoKeyFactory
     * @param proxyConversionHandler is the address of TwoKeyConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyAcquisitionCampaign is the address of TwoKeyAcquisitionCampaign proxy deployed by TwoKeyFactory
     * @param proxyPurchasesHandler is the address of TwoKeyPurchasesHandler proxy deployed by TwoKeyFactory
     */
    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));
        emit AcquisitionCampaignCreated(
            proxyLogicHandler,
            proxyConversionHandler,
            proxyAcquisitionCampaign,
            proxyPurchasesHandler,
            contractor
        );
    }

    /**
     * @notice Function to emit event every time someone starts new Donation campaign
     * @param proxyDonationCampaign is the address of TwoKeyDonationCampaign proxy deployed by TwoKeyFactory
     * @param proxyDonationConversionHandler is the address of TwoKeyDonationConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyDonationLogicHandler is the address of TwoKeyDonationLogicHandler proxy deployed by TwoKeyFactory
     */
    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));
        emit DonationCampaignCreated(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            contractor
        );
    }

    /**
     * @notice Function which will emit event PriceUpdated every time that happens under TwoKeyExchangeRateContract
     * @param _currency is the hexed string of currency name
     * @param _newRate is the new rate
     * @param _timestamp is the time of updating
     * @param _updater is the maintainer address which performed this call
     */
    function priceUpdated(
        bytes32 _currency,
        uint _newRate,
        uint _timestamp,
        address _updater
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract"));
        emit PriceUpdated(_currency, _newRate, _timestamp, _updater);
    }

    /**
     * @notice Function to emit event every time user is registered
     * @param _name is the name of the user
     * @param _address is the address of the user
     * @param _fullName is the full user name
     * @param _email is users email
     * @param _username_walletName is = concat(username,'_',walletName)
     */
    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external
    {
        require(isAddressMaintainer(msg.sender) == true);
        emit UserRegistered(_name, _address, _fullName, _email, _username_walletName);
    }
    /**
     * @notice Function to check adequate plasma address for submitted eth address
     * @param me is the ethereum address we request corresponding plasma address for
     */
    function plasmaOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry");
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry");
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    /**
     * @notice Address to check if an address is maintainer in TwoKeyMaintainersRegistry
     * @param _maintainer is the address we're checking this for
     */
    function isAddressMaintainer(
        address _maintainer
    )
    public
    view
    returns (bool)
    {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        bool _isMaintainer = ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(_maintainer);
        return _isMaintainer;
    }

    /**
     * @notice In default TwoKeyAdmin will be moderator and his fee percentage per conversion is predefined
     */
    function getTwoKeyDefaultIntegratorFeeFromAdmin()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        uint integratorFeePercentage = ITwoKeyAdmin(twoKeyAdmin).getDefaultIntegratorFeePercent();
        return integratorFeePercentage;
    }

    /**
     * @notice Function to get default network tax percentage
     */
    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        uint networkTaxPercent = ITwoKeyAdmin(twoKeyAdmin).getDefaultNetworkTaxPercent();
        return networkTaxPercent;
    }
}
