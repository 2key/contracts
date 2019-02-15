pragma solidity ^0.4.24;

// @author Nikola Madjarevic
// @notice Contract which will act as an interface for only methods we need from AcquisitionCampaign in other contracts
contract ITwoKeyAcquisitionCampaignERC20 {
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter) public;
    function moveFungibleAsset(address _to, uint256 _amount) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelled(address _cancelledConverter, uint _conversionAmount) public;
    function updateModeratorBalanceETHWei(uint _value) public;
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(uint value) public;
    function refundConverterAndRemoveUnits(address _converter, uint amountOfEther, uint amountOfUnits) external;
    function getStatistics(address ethereum, address plasma) public view returns (uint,uint,uint);
    function getAvailableAndNonReservedTokensAmount() external view returns (uint);
}
