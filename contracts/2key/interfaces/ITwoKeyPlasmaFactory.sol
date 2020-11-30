pragma solidity ^0.4.24;

contract ITwoKeyPlasmaFactory {
    function isCampaignCreatedThroughFactory(address _campaignAddress) public view returns (bool);
    function addressToCampaignType(address _campaignAddress) public view returns (string);
}
