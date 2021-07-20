pragma solidity ^0.4.24;

contract ITwoKeyPlasmaCampaignsInventoryManager {
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    external;

    function addInventoryUSD(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    external;

    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    external;

    function rebalanceInfluencerRatesAndPrepareForRewardsDistribution(
        address referrer,
        uint currentRate2KEY
    )
    external;

    function finishDistributionCycle(
        address referrer,
        uint feePerReferrerIn2KEY
    )
    external;

    function pushAndDistributeRewardsBetweenInfluencers(
        address [] influencers,
        uint [] balances,
        address campaignAddressPlasma,
        uint feePerReferrerIn2Key
    )
    external;

    function getReferrerEarningsNonRebalanced(
        address referrer
    )
    external
    view
    returns (uint);

    function getReferrerEarningsRebalanced(
        address referrer
    )
    public
    view
    returns (uint)

    function getCampaignsInProgressOfDistribution(
        address referrer
    )
    external
    returns (address[]);

    function getCampaignInformation(
        address campaignAddressPlasma
    )
    external
    view;
}