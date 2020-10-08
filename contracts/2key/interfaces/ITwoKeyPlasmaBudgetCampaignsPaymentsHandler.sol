pragma solidity ^0.4.24;

contract ITwoKeyPlasmaBudgetCampaignsPaymentsHandler {
    function setRebalancedReferrerEarnings(
        address referrer,
        uint balance
    )
    external;

    function updateReferrerRewards(
        address referrer,
        uint amount
    )
    external;
}
