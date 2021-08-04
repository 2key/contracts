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

    function withdrawModeratorEarnings()
    external;

    function getModeratorTotalPlasmaBalance()
    external
    returns (uint, uint);

    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    external
    view
    returns (address[] memory);

    function getTotalReferrerBalanceOnL2PPCCampaigns2KEY(
        address referrer
    )
    external
    view
    returns (uint, address[] memory, uint[] memory);

    function getTotalReferrerBalanceOnL2PPCCampaignsUSD(
        address referrer
    )
    external
    view
    returns (uint, address[] memory, uint[] memory);

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