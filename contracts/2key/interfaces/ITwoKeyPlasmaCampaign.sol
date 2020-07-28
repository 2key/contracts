pragma solidity ^0.4.24;

contract ITwoKeyPlasmaCampaign {
    function computeAndSetRebalancingRatioForReferrer(
        address _referrer,
        uint _currentRate2KEY
    )
    public
    returns (uint,uint);

    function getActiveInfluencers(
        uint start,
        uint end
    )
    public
    view
    returns (address[]);

    function getReferrerPlasmaBalance(
        address _referrer
    )
    public
    view
    returns (uint);
}
