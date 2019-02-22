pragma solidity ^0.4.24;

import "../libraries/GetCode.sol";
import "../Upgradeable.sol";
import "../MaintainingPattern.sol";

import "../interfaces/ITwoKeyAcquisitionCampaignStateVariables.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";


/*******************************************************************************************************************
 *       General purpose of this contract is to validate the layer we can't control,
 *
 *
 *            *****************************************
 *            *  Contracts which are deployed by user *
 *            *  - TwoKeyAcquisitionCampaign          *
 *            *  - TwoKeyAcquisitionLogicHandler      *
 *            *  - TwoKeyConversionHandler            *
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


/**
 * @author Nikola Madjarevic
 * Created at 2/12/19
 */
contract TwoKeyCampaignValidator is Upgradeable, MaintainingPattern {

    address public twoKeySingletoneRegistry;
    mapping(address => string) public campaign2nonSingletonHash;


    mapping(bytes => bool) isCodeValid;
    mapping(bytes => bytes32) contractCodeToName;

    // Will store the mapping between campaign address and if it satisfies all the criteria
    mapping(address => bool) public isCampaignValidated;


    /**
     * @notice Function to set initial parameters in this contract
     * @param _twoKeySingletoneRegistry is the address of TwoKeySingletoneRegistry contract
     * @param _maintainers is the array of initial maintainer addresses
     */
    function setInitialParams(address _twoKeySingletoneRegistry, address [] _maintainers) {
        require(twoKeySingletoneRegistry == address(0));
        twoKeySingletoneRegistry = _twoKeySingletoneRegistry;
        twoKeyAdmin =  ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyAdmin");
        isMaintainer[msg.sender] = true;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which is in charge to validate if the campaign contract is ready
     * It should be called by contractor after he finish all the stuff necessary for campaign to work
     * @param campaign is the address of the campaign, in this particular case it's acquisition
     * @dev Validates all the required stuff, if the campaign is not validated, it can't touch our singletones
     */
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public {
        require(isCampaignValidated[campaign] == false);
        address contractor = ITwoKeyAcquisitionCampaignStateVariables(campaign).contractor();
        address moderator = ITwoKeyAcquisitionCampaignStateVariables(campaign).moderator(); //Moderator we'll need for emit event

        //Validating that the msg.sender is the contractor of the campaign provided
        require(msg.sender == contractor);
        //Validating that the Acquisition campaign holds exactly same TwoKeyLogicHandlerAddress
        require(twoKeySingletoneRegistry == ITwoKeyAcquisitionCampaignStateVariables(campaign).twoKeySingletonesRegistry());
        //Validating that the bytecode of the campaign and campaign helper contracts are eligible
        address conversionHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).conversionHandler();
        address logicHandler = ITwoKeyAcquisitionCampaignStateVariables(campaign).twoKeyAcquisitionLogicHandler();

        bytes memory codeAcquisition = GetCode.at(campaign);
        bytes memory codeHandler = GetCode.at(conversionHandler);
        bytes memory codeLogicHandler = GetCode.at(logicHandler);

        require(isCodeValid[codeAcquisition] == true);
        require(isCodeValid[codeHandler] == true);
        require(isCodeValid[codeLogicHandler] == true);

        //Validate that public link key is set
        require(ITwoKeyAcquisitionCampaignStateVariables(campaign).publicLinkKeyOf(contractor) != address(0));

        //If the campaign passes all this validation steps means it's valid one, and it can be proceeded forward
        isCampaignValidated[campaign] = true;

        //Adding campaign 2 non singleton hash at the moment
        campaign2nonSingletonHash[campaign] = nonSingletonHash;

        //Get the event source address
        address twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress
                                    (twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyEventSource");

        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
    }

    /**
     * @notice Function to add valid bytecodes for the contracts
     * @param contracts is the array of contracts (deployed)
     * @names is the array of hexed contract names
     * @dev Only maintainer can issue calls to this function
     */
    function addValidBytecodes(address[] contracts, bytes32[] names) public onlyMaintainer {
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
    function removeBytecode(bytes _bytecode) public onlyMaintainer {
        isCodeValid[_bytecode] = false;
    }

    /**
     * @notice Function to validate if specific conversion handler code is valid
     * @param _conversionHandler is the address of already deployed conversion handler
     * @return true if code is valid and responds to conversion handler contract
     */
    function isConversionHandlerCodeValid(address _conversionHandler) public view returns (bool) {
        bytes memory contractCode = GetCode.at(_conversionHandler);
        require(isCodeValid[contractCode]);
        bytes32 name = stringToBytes32("TWO_KEY_CONVERSION_HANDLER");
        require(contractCodeToName[contractCode] == name);
        return true;
    }


    /**
     * @notice Pure function to convert input string to hex
     * @param source is the input string
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}
