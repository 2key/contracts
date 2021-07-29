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

    function endCampaignAndTransferModeratorEarnings(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    external;

    function withdrawReferrerPendingRewards(
        address referrer
    )
    external;

    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    external
    view
    returns (address[]);

    function getTotalReferrerPendingAmount(
        address referrer
    )
    external
    view
    returns (uint, uint);

    function pushAddressToArray(
        bytes32 key,
        address value
    )
    external;

    function deleteAddressArray(
        bytes32 key
    )
    external;

    function getCampaignInformation(
        address campaignAddressPlasma
    )
    external
    view
    returns(address, uint[], bool[]);
}