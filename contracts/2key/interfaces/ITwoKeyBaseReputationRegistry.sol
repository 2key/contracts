pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/4/19
 */
contract ITwoKeyBaseReputationRegistry {
    function updateOnConversionCreatedEvent(address converter, address contractor, address acquisitionCampaign) public;
    function updateOnConversionExecutedEvent(address converter, address contractor, address acquisitionCampaign) public;
    function updateOnConversionRejectedEvent(address converter, address contractor, address acquisitionCampaign) public;
}
