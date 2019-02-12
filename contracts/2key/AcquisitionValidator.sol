pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyAcquisitionCampaignGetStaticAddresses.sol";


/**
 * @author Nikola Madjarevic
 * Created at 2/12/19
 */
contract AcquisitionValidator {

    address twoKeySingletoneRegistry;

    mapping(bytes => bool) canEmit;

    constructor(address _twoKeySingletoneRegistry) {
        twoKeySingletoneRegistry = _twoKeySingletoneRegistry;
    }

    mapping(address => bool) isCampaignValidated;

//    function validateCampaign(address campaign) public {
//        //Validating that the msg.sender is the contractor of the campaign provided
//        require(msg.sender == ITwoKeyAcquisitionCampaignGetStaticAddresses(campaignAddress).contractor());
//        //Validating that the Acquisition campaign holds exactly same TwoKeyLogicHandlerAddress
//        require(twoKeySingletoneRegistry == ITwoKeyAcquisitionCampaignGetStaticAddresses(campaignAddress).twoKeySingletonesRegistry());
//        //
//
//
//    }
}
