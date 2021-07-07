pragma solidity ^0.4.24;

contract ITwoKeyPlasmaCampaignsInventory {
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

    function withdrawLeftoverForContractor(
        address campaignPlasmaAddress
    )
    external;

    function pushAndDistributeRewardsBetweenInfluencers(
        address [] influencers,
        uint [] balances,
        uint nonRebalancedTotalPayout,
        uint rebalancedTotalPayout,
        uint cycleId,
        uint feePerReferrerIn2Key
    )
    external;

    function getCampaignInformation(
        address campaignAddressPlasma
    )
    external
    view;
}