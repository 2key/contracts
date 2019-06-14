pragma solidity ^0.4.24;

import "../libraries/GetCode.sol";

import "../interfaces/ITwoKeyAcquisitionCampaignStateVariables.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../interfaces/ITwoKeyCampaignPublicAddresses.sol";
import "../interfaces/ITwoKeyDonationCampaign.sol";
import "../interfaces/ITwoKeyDonationCampaignFetchAddresses.sol";
import "../interfaces/IGetImplementation.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/IStructuredStorage.sol";
import "../upgradability/Upgradeable.sol";


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
contract TwoKeyCampaignValidator is Upgradeable {

    bool initialized;

    address public TWO_KEY_SINGLETON_REGISTRY;
    address public STORAGE_PROXY_ADDRESS;


    mapping(address => string) public campaign2nonSingletonHash;
    mapping(bytes => bool) isCodeValid;
    mapping(bytes => bytes32) contractCodeToName;

    // Will store the mapping between campaign address and if it satisfies all the criteria
    mapping(address => bool) public isCampaignValidated;


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
        STORAGE_PROXY_ADDRESS = _proxyStorage;

        initialized = true;
    }

    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry =
        ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
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
        require(isCampaignValidated[campaign] == false);
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));

        address contractor = ITwoKeyAcquisitionCampaignStateVariables(campaign).contractor();
        address moderator = ITwoKeyAcquisitionCampaignStateVariables(campaign).moderator();

        //Validating that the bytecode of the campaign and campaign helper contracts are eligible
        address conversionHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).conversionHandler();
        address logicHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).twoKeyAcquisitionLogicHandler();

        address campaignImplementation = IGetImplementation(campaign).implementation();
        address conversionHandlerImplementation = IGetImplementation(conversionHandler).implementation();
        address logicHandlerImplementation = IGetImplementation(logicHandler).implementation();

        bytes memory codeAcquisition = GetCode.at(campaignImplementation);
        bytes memory codeHandler = GetCode.at(conversionHandlerImplementation);
        bytes memory codeLogicHandler = GetCode.at(logicHandlerImplementation);

        require(isCodeValid[codeAcquisition] == true);
        require(isCodeValid[codeHandler] == true);
        require(isCodeValid[codeLogicHandler] == true);


        //If the campaign passes all this validation steps means it's valid one, and it can be proceeded forward
        isCampaignValidated[campaign] = true;

        //Adding campaign 2 non singleton hash at the moment
        campaign2nonSingletonHash[campaign] = nonSingletonHash;

        //Get the event source address
        address twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress
                                    (TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress("TwoKeyEventSource");

        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
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
        require(isCampaignValidated[campaign] == false);
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFactory"));

        address contractor = ITwoKeyAcquisitionCampaignStateVariables(campaign).contractor();
        address moderator = ITwoKeyAcquisitionCampaignStateVariables(campaign).moderator();

        address campaignImplementation = IGetImplementation(campaign).implementation();
        address conversionHandlerImplementation = IGetImplementation(donationConversionHandler).implementation();

        bytes memory donationCampaignCode = GetCode.at(campaignImplementation);
        bytes memory donationConversionHandlerCode = GetCode.at(conversionHandlerImplementation);


        //Validate that this bytecode is validated and added
        require(isCodeValid[donationCampaignCode] == true);
        require(isCodeValid[donationConversionHandlerCode] == true);


        campaign2nonSingletonHash[campaign] = nonSingletonHash;

        isCampaignValidated[campaign] = true;

        //Get the event source
        address twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress
        (TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress("TwoKeyEventSource");

        //Emit the event that campaign is created
        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
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
            isCodeValid[contractCode] = true;
            contractCodeToName[contractCode] = names[i];
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
        isCodeValid[_bytecode] = false;
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
        require(isCodeValid[contractCode]);
        bytes32 name = stringToBytes32("TwoKeyConversionHandler");
        require(contractCodeToName[contractCode] == name);
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
        return isCodeValid[contractCode];
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

    // Internal wrapper methods
    function getBoolean(bytes32 key) internal view returns (bool) {
        return ITwoKeyUpgradableExchangeStorage(PROXY_STORAGE_CONTRACT).
        getBool(key);
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }
}
