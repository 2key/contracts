pragma solidity ^0.4.24;

// @author Nikola Madjarevic
contract ITwoKeyAcquisitionCampaignERC20 {
    address public logicHandler;  // Contract which will handle logic
    function buyTokensAndDistributeReferrerRewards(uint256 _maxReferralRewardETHWei, address _converter, uint _conversionId, bool _isConversionFiat) public returns (uint);
    function moveFungibleAsset(address _to, uint256 _amount) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelledOrRejected(address _cancelledConverter, uint _conversionAmount) public;
    function buyTokensForModeratorRewards(uint moderatorFee) public;
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(uint value) public;
    function refundConverterAndRemoveUnits(address _converter, uint amountOfEther, uint amountOfUnits) external;
    function getStatistics(address ethereum, address plasma) public view returns (uint,uint,uint,uint);
    function getAvailableAndNonReservedTokensAmount() external view returns (uint);
    function getTotalReferrerEarnings(address _referrer, address eth_address) public view returns (uint);
    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function getInventoryBalance() public view returns (uint);
    function validateThatThereIsEnoughTokensAndIncreaseReserved(uint totalBoughtUnits) public;
}
