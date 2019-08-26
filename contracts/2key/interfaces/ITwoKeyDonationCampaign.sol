pragma solidity ^0.4.24;

contract ITwoKeyDonationCampaign {

    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public;

    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint);

    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionRejected(address _rejectedConverter, uint _conversionAmount) public;
}
