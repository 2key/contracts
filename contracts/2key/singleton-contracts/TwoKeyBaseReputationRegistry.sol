pragma solidity ^0.4.24;


import "../upgradability/Upgradeable.sol";

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "./ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyBaseReputationRegistryStorage.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyBaseReputationRegistry is Upgradeable, ITwoKeySingletonUtils {


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
        validateCall();
        int d = 1;
        int initialRewardWei = 10*(10**18);

        bytes32 keyHashContractorScore = keccak256("address2contractorGlobalReputationScoreWei", contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + initialRewardWei);

        bytes32 keyHashConverterScore = keccak256("address2converterGlobalReputationScoreWei", converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + initialRewardWei);

        address[] memory referrers = getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            bytes32 keyHashReferrerScore = keccak256("plasmaAddress2referrerGlobalReputationScoreWei", referrers[i]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + initialRewardWei/d);
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
        validateCall();
        int d = 1;
        int initialRewardWei = 5*(10**18);


        bytes32 keyHashContractorScore = keccak256("address2contractorGlobalReputationScoreWei", contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore - initialRewardWei);

        bytes32 keyHashConverterScore = keccak256("address2converterGlobalReputationScoreWei", converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore - initialRewardWei);

        address[] memory referrers = getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            bytes32 keyHashReferrerScore = keccak256("plasmaAddress2referrerGlobalReputationScoreWei", referrers[i]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - initialRewardWei/d);
            d = d + 1;
        }
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
        return ITwoKeyCampaign(acquisitionCampaign).logicHandler();
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
        return ITwoKeyCampaign(acquisitionCampaign).conversionHandler();
    }

    /**
     * @notice Function to validate that the call is comming from validated campaign
     */
    function validateCall()
    internal
    view
    {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
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
        return ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter);
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
    returns (int,int,int)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress("TwoKeyRegistry");
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(_address);

        bytes32 keyHashContractorScore = keccak256("address2contractorGlobalReputationScoreWei", _address);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        bytes32 keyHashConverterScore = keccak256("address2converterGlobalReputationScoreWei", _address);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);

        bytes32 keyHashReferrerScore = keccak256("plasmaAddress2referrerGlobalReputationScoreWei", plasma);
        int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);


        return (
            contractorScore,
            converterScore,
            referrerScore
        );

    }

}
