pragma solidity ^0.4.24;

// @author Nikola Madjarevic
// @notice Contract which will act as an interface for only methods we need from AcquisitionCampaign in other contracts
contract ITwoKeyAcquisitionCampaignERC20 {
    function getSymbol() public view returns (string);
    function getAssetContractAddress() public view returns (address);
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter) public;
    function moveFungibleAsset(address _to, uint256 _amount) public returns (bool);
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelled(address _cancelledConverter, uint _conversionAmount) public;
    function updateModeratorBalanceETHWei(uint _value) public;
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(uint value) public;
    function refundConverterAndRemoveUnits(address _converter, uint amountOfEther, uint amountOfUnits) external;
    function getAddressJoinedStatus(address _address) public view returns (bool);
    function getAddressStatistic(address _address) public view returns (bytes);
}
