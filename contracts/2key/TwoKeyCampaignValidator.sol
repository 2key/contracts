pragma solidity ^0.4.24;

import "./GetCode.sol";
import "./Upgradeable.sol";
import "./MaintainingPattern.sol";

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

    mapping(bytes => bool) acquisitionToEligibleCode;
    mapping(bytes => bool) conversionHandlerToEligibleCode;
    mapping(bytes => bool) acquisitionLogicHandlerToEligibleCode;

    function setInitialParams(address _twoKeySingletoneRegistry, address [] _maintainers) {
        require(twoKeySingletoneRegistry == address(0));
        twoKeySingletoneRegistry = _twoKeySingletoneRegistry;
        twoKeyAdmin =  ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyAdmin");
        isMaintainer[msg.sender] = true;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    // Will store the mapping between campaign address and if it satisfies all the criteria
    mapping(address => bool) public isCampaignValidated;


    /**
     * @notice Function which is in charge to validate if the campaign contract is ready
     * It should be called by contractor after he finish all the stuff necessary for campaign to work
     * @param campaign is the address of the campaign, in this particular case it's acquisition
     * @dev Validates all the required stuff, if the campaign is not validated, it can't touch our singletones
     */
    function validateAcquisitionCampaign(address campaign) public {
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

        require(acquisitionToEligibleCode[codeAcquisition] == true);
        require(conversionHandlerToEligibleCode[codeHandler] == true);
        require(acquisitionLogicHandlerToEligibleCode[codeLogicHandler] == true);

        //Validate that public link key is set
        require(ITwoKeyAcquisitionCampaignStateVariables(campaign).publicLinkKeyOf(contractor) != address(0));
        //Validate that inventory is added and asset contract is set at the same time
        require(ITwoKeyAcquisitionCampaignStateVariables(campaign).getInventoryBalance() > 0);

        //If the campaign passes all this validation steps means it's valid one, and it can be proceeded forward
        isCampaignValidated[campaign] = true;

        //Get the event source address
        address twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress
                                    (twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyEventSource");

        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
    }

    function addValidBytecodes(address campaign, address conversionHandler, address logicHandler) public onlyMaintainer {
        bytes memory campaignCode = GetCode.at(campaign);
        bytes memory conversionHandlerCode = GetCode.at(conversionHandler);
        bytes memory logicHandlerCode = GetCode.at(logicHandler);

        //TODO: If we're going to support different versions combined, in that particular case, use the superhash enough
        acquisitionToEligibleCode[campaignCode] = true;
        conversionHandlerToEligibleCode[conversionHandlerCode] = true;
        acquisitionLogicHandlerToEligibleCode[logicHandlerCode] = true;
    }

}
