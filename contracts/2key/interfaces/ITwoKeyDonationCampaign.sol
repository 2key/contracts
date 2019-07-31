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

    function getReferrerPlasmaBalance(address _influencer) public view returns (uint);
    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function getReferrerCut(address me) public view returns (uint256);
    function updateContractorProceeds(uint value) public;
    function getReceivedFrom(address _receiver) public view returns (address);
    function balanceOf(address _owner) public view returns (uint256);
    function sendBackEthWhenConversionRejected(address _rejectedConverter, uint _conversionAmount) public;
}
