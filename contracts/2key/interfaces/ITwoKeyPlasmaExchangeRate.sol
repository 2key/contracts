pragma solidity ^0.4.24;

contract ITwoKeyPlasmaExchangeRate {
    function getPairValue(string name) external view returns (uint);
}