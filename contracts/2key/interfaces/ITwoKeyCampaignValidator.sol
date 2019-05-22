pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/12/19
 */
contract ITwoKeyCampaignValidator {
    mapping(address => bool) public isCampaignValidated;
    function isConversionHandlerCodeValid(address conversionHandler) public view returns (bool);
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public;
    function validateDonationCampaign(address campaign, address donationConversionHandler, string nonSingletonHash) public;
}
