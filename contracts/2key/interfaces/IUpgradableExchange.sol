pragma solidity ^0.4.24;

contract IUpgradableExchange {

    uint256 public rate;

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
