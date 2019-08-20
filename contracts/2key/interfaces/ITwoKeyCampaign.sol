pragma solidity ^0.4.24;

contract ITwoKeyCampaign {

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
}
