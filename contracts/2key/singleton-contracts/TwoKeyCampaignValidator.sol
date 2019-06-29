pragma solidity ^0.4.24;

import "../libraries/GetCode.sol";

import "../interfaces/ITwoKeyAcquisitionCampaignStateVariables.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../interfaces/ITwoKeyCampaignPublicAddresses.sol";
import "../interfaces/ITwoKeyDonationCampaign.sol";
import "../interfaces/ITwoKeyDonationCampaignFetchAddresses.sol";
import "../interfaces/IGetImplementation.sol";
import "../interfaces/IStructuredStorage.sol";
import "../interfaces/storage-contracts/ITwoKeyCampaignValidatorStorage.sol";

import "../upgradability/Upgradeable.sol";
import "./ITwoKeySingletonUtils.sol";


/*******************************************************************************************************************
 *       General purpose of this contract is to validate the layer we can't control,
 *
 *
 *            *****************************************
 *            *  Contracts which are deployed by user *
 *            *  - TwoKeyAcquisitionCampaign          *
 *            *  - TwoKeyAcquisitionLogicHandler      *
 *            *  - TwoKeyConversionHandler            *
              *  - TwoKeyDonationCampaign             *
              *  - TwoKeyDonationConversionHandler    *
 *            *****************************************
 *                               |
 *                               |
 *                               |
 *            *****************************************
 *            *   Contract that validates everything  *      Permits        ************************************
 *            *   in the contracts deployed above     * ------------------> * Interaction with our singletones *
 *            *****************************************                     ************************************
 *
 ******************************************************************************************************************/
// Mappings will be stored as keccak(mappingName, mappingKey)


/**
 * @author Nikola Madjarevic
 * Created at 2/12/19
 */
contract TwoKeyCampaignValidator is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    ITwoKeyCampaignValidatorStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function to set initial parameters in this contract
     * @param _twoKeySingletoneRegistry is the address of TwoKeySingletoneRegistry contract
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyCampaignValidatorStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice Function which is in charge to validate if the campaign contract is ready
     * It should be called by contractor after he finish all the stuff necessary for campaign to work
     * @param campaign is the address of the campaign, in this particular case it's acquisition
     * @dev Validates all the required stuff, if the campaign is not validated, it can't update our singletones
     */
    function validateAcquisitionCampaign(
        address campaign,
        string nonSingletonHash
    )
    public
    {
        bytes32 hashIsCampaignValidated = keccak256("isCampaignValidated",campaign);

        require(PROXY_STORAGE_CONTRACT.getBool(hashIsCampaignValidated) == false);
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));

        //Validating that the bytecode of the campaign and campaign helper contracts are eligible
        address conversionHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).conversionHandler();
        address logicHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).twoKeyAcquisitionLogicHandler();

        address campaignImplementation = IGetImplementation(campaign).implementation();
        address conversionHandlerImplementation = IGetImplementation(conversionHandler).implementation();
        address logicHandlerImplementation = IGetImplementation(logicHandler).implementation();

        bytes memory codeAcquisition = GetCode.at(campaignImplementation);
        bytes memory codeHandler = GetCode.at(conversionHandlerImplementation);
        bytes memory codeLogicHandler = GetCode.at(logicHandlerImplementation);

        require(PROXY_STORAGE_CONTRACT.getBool(keccak256("isCodeValid", codeAcquisition)) == true);
        require(PROXY_STORAGE_CONTRACT.getBool(keccak256("isCodeValid", codeHandler)) == true);
        require(PROXY_STORAGE_CONTRACT.getBool(keccak256("isCodeValid", codeLogicHandler)) == true);


        //If the campaign passes all this validation steps means it's valid one, and it can be proceeded forward
        PROXY_STORAGE_CONTRACT.setBool(hashIsCampaignValidated, true);

        //Adding campaign 2 non singleton hash at the moment
        PROXY_STORAGE_CONTRACT.setString(keccak256("campaign2NonSingletonHash",campaign), nonSingletonHash);
        emitCreatedEvent(campaign);
    }

    /**
     * @notice Function to validate Donation campaign if it is ready
     * @param campaign is the campaign address
     * @dev Validates all the required stuff, if the campaign is not validated, it can't update our singletones
     */
    function validateDonationCampaign(
        address campaign,
        address donationConversionHandler,
        string nonSingletonHash
    )
    public
    {
        bytes32 hashIsCampaignValidated = keccak256("isCampaignValidated",campaign);
        require(PROXY_STORAGE_CONTRACT.getBool(hashIsCampaignValidated) == false);

        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));

        address campaignImplementation = IGetImplementation(campaign).implementation();
        address conversionHandlerImplementation = IGetImplementation(donationConversionHandler).implementation();

        bytes memory donationCampaignCode = GetCode.at(campaignImplementation);
        bytes memory donationConversionHandlerCode = GetCode.at(conversionHandlerImplementation);

        bytes32 hashIsValidCodeDonation = keccak256("isCodeValid", donationCampaignCode);
        bytes32 hashIsValidCodeHandler = keccak256("isCodeValid", donationConversionHandlerCode);

        //Validate that this bytecode is validated and added
        require(PROXY_STORAGE_CONTRACT.getBool(hashIsValidCodeDonation) == true);
        require(PROXY_STORAGE_CONTRACT.getBool(hashIsValidCodeHandler) == true);

        PROXY_STORAGE_CONTRACT.setBool(hashIsCampaignValidated, true);

        bytes32 hashCampaignToNonSingletonHash = keccak256("campaign2NonSingletonHash",campaign);
        PROXY_STORAGE_CONTRACT.setString(hashCampaignToNonSingletonHash, nonSingletonHash);

        emitCreatedEvent(campaign);
    }

    /**
     * @notice Function to add valid bytecodes for the contracts
     * @param contracts is the array of contracts (deployed)
     * @param names is the array of hexed contract names
     * @dev Only maintainer can issue calls to this function
     */
    function addValidBytecodes(
        address[] contracts,
        bytes32[] names
    )
    public
    onlyMaintainer
    {
        require(contracts.length == names.length);
        uint length = contracts.length;
        for(uint i=0; i<length; i++) {
            bytes memory contractCode = GetCode.at(contracts[i]);

            bytes32 hashIsCodeValid = keccak256("isCodeValid", contractCode);
            bytes32 hashCodeToName = keccak256("contractCodeToName",names[i]);

            PROXY_STORAGE_CONTRACT.setBool(hashIsCodeValid, true);
            PROXY_STORAGE_CONTRACT.setBytes32(hashCodeToName, names[i]);
        }
    }

    /**
     * @notice Function to remove bytecode of the contract from whitelisted ones
     */
    function removeBytecode(
        bytes _bytecode
    )
    public
    onlyMaintainer
    {
        bytes32 hashIsCodeValid = keccak256("isCodeValid", _bytecode);
        PROXY_STORAGE_CONTRACT.setBool(hashIsCodeValid, false);
    }

    /**
     * @notice Function to validate if specific conversion handler code is valid
     * @param _conversionHandler is the address of already deployed conversion handler
     * @return true if code is valid and responds to conversion handler contract
     */
    function isConversionHandlerCodeValid(
        address _conversionHandler
    )
    public
    view
    returns (bool)
    {
        address implementation = IGetImplementation(_conversionHandler).implementation();
        bytes memory contractCode = GetCode.at(implementation);
        bytes32 hashIsCodeValid = keccak256("isCodeValid", contractCode);
        require(PROXY_STORAGE_CONTRACT.getBool(hashIsCodeValid) == true);

        bytes32 name = stringToBytes32("TwoKeyConversionHandler");
        bytes32 hashContractCodeToName = keccak256("contractCodeToName",name);

        require(PROXY_STORAGE_CONTRACT.getBytes32(hashContractCodeToName) == name);

        return true;
    }

    function isContractCodeAddressValidated(
        address _contract
    )
    public
    view
    returns (bool)
    {
        address implementation = IGetImplementation(_contract).implementation();
        bytes memory contractCode = GetCode.at(implementation);
        bytes32 hashIsCodeValid = keccak256("isCodeValid", contractCode);
        return PROXY_STORAGE_CONTRACT.getBool(hashIsCodeValid);
    }

    /**
     * @notice Pure function to convert input string to hex
     * @param source is the input string
     */
    function stringToBytes32(
        string memory source
    )
    internal
    pure
    returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function isCampaignValidated(address campaign) public view returns (bool) {
        bytes32 hashKey = keccak256("isCampaignValidated", campaign);
        return PROXY_STORAGE_CONTRACT.getBool(hashKey);
    }

    function campaign2NonSingletonHash(address campaign) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256("campaign2NonSingletonHash", campaign));
    }


    function emitCreatedEvent(address campaign) internal {
        address contractor = ITwoKeyAcquisitionCampaignStateVariables(campaign).contractor();
        address moderator = ITwoKeyAcquisitionCampaignStateVariables(campaign).moderator();

        //Get the event source address
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource");
        // Emit event
        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
    }
}
