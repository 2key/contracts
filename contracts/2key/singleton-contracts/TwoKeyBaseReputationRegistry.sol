pragma solidity ^0.4.24;


import "../upgradability/Upgradeable.sol";

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignStateVariables.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../libraries/SafeMath.sol";
import "./ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyBaseReputationRegistryStorage.sol";

/**
 * @author Nikola Madjarevic
 * Created at 1/31/19
 */
contract TwoKeyBaseReputationRegistry is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint;

    bool initialized;

    ITwoKeyBaseReputationRegistryStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Since using singletone pattern, this is replacement for the constructor
     * @param _twoKeySingletoneRegistry is the address of registry of all singleton contracts
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBaseReputationRegistryStorage(_proxyStorage);

        initialized = true;
    }

    mapping(address => int) public address2contractorGlobalReputationScoreWei;
    mapping(address => int) public address2converterGlobalReputationScoreWei;
    mapping(address => int) public plasmaAddress2referrerGlobalReputationScoreWei;


    /**
     * @notice If the conversion executed event occured, 10 points for the converter and contractor + 10/distance to referrer
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionExecutedEvent(
        address converter,
        address contractor,
        address acquisitionCampaign
    )
    public
    {
        validateCall(acquisitionCampaign);
        int d = 1;
        int initialRewardWei = 10*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);

        address2contractorGlobalReputationScoreWei[contractor] = initialRewardWei + address2contractorGlobalReputationScoreWei[contractor];
        address2converterGlobalReputationScoreWei[converter] = initialRewardWei + address2converterGlobalReputationScoreWei[converter];

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] = initialRewardWei/d + plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]];
            d = d + 1;
        }
    }

    /**
     * @notice If the conversion rejected event occured, giving penalty points
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionRejectedEvent(
        address converter,
        address contractor,
        address acquisitionCampaign
    )
    public
    {
        validateCall(acquisitionCampaign);
        int d = 1;
        int initialPenaltyWei = 5*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);

        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] - initialPenaltyWei;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] - initialPenaltyWei;
        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);
        plasmaAddress2referrerGlobalReputationScoreWei[referrers[0]] = plasmaAddress2referrerGlobalReputationScoreWei[referrers[0]] - initialPenaltyWei;
    }


    /**
     * @notice Internal getter from Acquisition campaign to fetch logic handler address
     */
    function getLogicHandlerAddress(
        address acquisitionCampaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyAcquisitionCampaignStateVariables(acquisitionCampaign).twoKeyAcquisitionLogicHandler();
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch conersion handler address
     */
    function getConversionHandlerAddress(
        address acquisitionCampaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyAcquisitionCampaignStateVariables(acquisitionCampaign).conversionHandler();
    }

    /**
     * @notice Function to validate call to method
     */
    function validateCall(
        address acquisitionCampaign
    )
    internal
    {
        address conversionHandler = getConversionHandlerAddress(acquisitionCampaign);
        require(msg.sender == conversionHandler);
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(acquisitionCampaign) == true);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isConversionHandlerCodeValid(conversionHandler) == true);
    }

    /**
     * @notice Function to get all referrers in the chain for specific converter
     * @param converter is the converter we want to get referral chain
     * @param acquisitionCampaign is the acquisition campaign contract
     * @return array of addresses (referrers)
     */
    function getReferrers(
        address converter,
        address acquisitionCampaign
    )
    internal
    view
    returns (address[])
    {
        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        return ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);
    }

    /**
     * @notice Function to fetch reputation points per address
     * @param _address is the address of the user we want to check points for
     * @return encoded values in type bytes, unpackable by slices of 66,2,64,2,64,2 parsed to int / bool
     */
    function getRewardsByAddress(
        address _address
    )
    public
    view
    returns (bytes)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress("TwoKeyRegistry");
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(_address);

        int reputationAsContractor = address2contractorGlobalReputationScoreWei[_address];
        int reputationAsConverter = address2converterGlobalReputationScoreWei[_address];
        int reputationAsReferrer = plasmaAddress2referrerGlobalReputationScoreWei[plasma];


        return abi.encodePacked(
            reputationAsContractor,
            true,
            reputationAsConverter,
            true,
            reputationAsReferrer,
            true
        );

    }

}
