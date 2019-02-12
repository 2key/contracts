pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract ITwoKeyAcquisitionLogicHandler {
    function requirementForMsgValue(uint msgValue) public view returns (bool);
    function getEstimatedTokenAmount(uint conversionAmountETHWei, bool isFiatConversion) public view returns (uint, uint);
    function setTwoKeyAcquisitionCampaignContract(address _acquisitionCampaignAddress, address twoKeySingletoneRegistry) public;
    function getReferrers(address customer, address acquisitionCampaignContract) public view returns (address[]);
}
