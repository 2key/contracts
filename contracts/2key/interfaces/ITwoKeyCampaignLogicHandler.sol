pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract ITwoKeyCampaignLogicHandler {
    function canContractorWithdrawRemainingRewardsInventory() public view returns (bool);
    function reduceTotalRaisedFundsAfterConversionRejected(uint amountToReduce) public;
}
