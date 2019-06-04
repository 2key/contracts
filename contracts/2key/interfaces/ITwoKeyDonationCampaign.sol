pragma solidity ^0.4.0;

contract ITwoKeyDonationCampaign {
    function distributeReferrerRewards(
        address converter,
        uint referrer_rewards,
        uint donationId
    )
    public
    returns (uint);


    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public;


    function updateContractorBalanceAndConverterDonations(
        address _converter,
        uint earningsContractor,
        uint donationsConverter
    ) public;
}
