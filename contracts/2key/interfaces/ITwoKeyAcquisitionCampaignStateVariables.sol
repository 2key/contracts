pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/4/19
 */
contract ITwoKeyAcquisitionCampaignStateVariables {
    address public contractor;
    address public moderator;
    address public twoKeySingletonesRegistry;
    address public twoKeyAcquisitionLogicHandler;
    address public conversionHandler;

    function publicLinkKeyOf(address me) public view returns (address);
    function getInventoryBalance() public view returns (uint);

}
