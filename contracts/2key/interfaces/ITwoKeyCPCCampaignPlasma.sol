pragma solidity ^0.4.24;

contract ITwoKeyCPCCampaignPlasma {
    function getReferrers(
        address customer
    )
    external
    view
    returns (address[]);

    function setInitialParamsAndValidateCampaign(
        uint _totalBounty,
        uint _initialRate2KEY,
        uint _bountyPerConversion2KEY,
        bool _isBudgetedDirectlyWith2KEY
    ) external;

    function addCampaignBounty(
        uint _addedBounty,
        bool _isBudgetedDirectlyWith2KEY
    )
    external;
}
