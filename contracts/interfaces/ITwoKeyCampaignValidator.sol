pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/12/19
 */
contract ITwoKeyCampaignValidator {
    mapping(address => bool) public isCampaignValidated;
    function validateAcquisitionCampaign(address campaign) public;
}
