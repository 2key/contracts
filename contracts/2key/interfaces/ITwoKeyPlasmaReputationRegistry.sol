pragma solidity ^0.4.24;

contract ITwoKeyPlasmaReputationRegistry {

    function updateReputationPointsForExecutedConversion(
        address converter,
        address contractor
    )
    public;

    function updateReputationPointsForRejectedConversions(
        address converter,
        address contractor
    )
    public;

    function updateUserReputationScoreOnSignup(
        address _plasmaAddress
    )
    public;
}
