pragma solidity ^0.4.24;

// @author Nikola Madjarevic
contract ITwoKeyCPCCampaign {
    function buyTokensForModeratorRewards(uint moderatorFee) public;
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(uint value) public;
    function refundConverterAndRemoveUnits(address _converter, uint amountOfEther, uint amountOfUnits) external;
    function getStatistics(address ethereum, address plasma) public view returns (uint,uint,uint,uint);
    function getAvailableAndNonReservedTokensAmount() external view returns (uint);
    function getTotalReferrerEarnings(address _referrer, address eth_address) public view returns (uint);
    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function getInventoryBalance() public view returns (uint);
}
