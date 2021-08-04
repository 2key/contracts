pragma solidity ^0.4.24;

contract ITwoKeyPlasmaCampaign {
    // function markReferrerReceivedPaymentForThisCampaign(
    //     address _referrer
    // )
    // external;

    function withdrawReferrerCamapignEarningsL2(
        address _referrer
    )
    external;

    // function computeAndSetRebalancingRatioForReferrer(
    //     address _referrer,
    //     uint _currentRate2KEY
    // )
    // external
    // returns (uint,uint);

    function getActiveInfluencers(
        uint start,
        uint end
    )
    external
    view
    returns (address[]);

    function getTotalReferrerRewardsEarned()
    external
    view
    returns (uint);

    function getReferrerPlasmaBalance(
        address _referrer
    )
    external
    view
    returns (uint);

    function setInitialParamsAndValidateCampaign(
        uint _totalBounty,
        uint _initialRate2KEY,
        uint _bountyPerConversionWei,
        bool _isBudgetedDirectlyWith2KEY
    )
    external;

    function addCampaignBounty(
        uint _addedBounty,
        bool _isBudgetedDirectlyWith2KEY
    )
    external;

    function getModeratorTotalEarningsAndBalance()
    external
    view
    returns (uint, uint);

    function withdrawModeratorCamapignEarningsL2()
    external;

    function getTotalReferrerRewardsAndTotalModeratorEarnings()
    external
    view
    returns (uint,uint);
}
