pragma solidity ^0.4.24;

contract IUpgradableExchange {

    uint public buyRate2key;
    uint public sellRate2key;

    function buyTokens(
        address _beneficiary
    )
    public
    payable
    returns (uint);

    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    payable
    returns (uint);
}
