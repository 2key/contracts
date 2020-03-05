pragma solidity ^0.4.24;

contract ITwoKeyCampaign {

    function getNumberOfUsersToContractor(
        address _user
    )
    public
    view
    returns (uint);

    function getReceivedFrom(
        address _receiver
    )
    public
    view
    returns (address);

    function balanceOf(
        address _owner
    )
    public
    view
    returns (uint256);

    function getReferrerCut(
        address me
    )
    public
    view
    returns (uint256);

    function getReferrerPlasmaBalance(
        address _influencer
    )
    public
    view
    returns (uint);

    function updateReferrerPlasmaBalance(
        address _influencer,
        uint _balance
    )
    public;

    function updateModeratorRewards(
        uint moderatorTokens
    )
    public;

    address public logicHandler;
    address public conversionHandler;

}
