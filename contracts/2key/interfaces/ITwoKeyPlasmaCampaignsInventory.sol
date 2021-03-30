pragma solidity ^0.4.24;

contract ITwoKeyPlasmaCampaignsInventory {
    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    external;
}