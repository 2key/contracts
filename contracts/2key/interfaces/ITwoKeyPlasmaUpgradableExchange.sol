pragma solidity ^0.4.24;

contract ITwoKeyPlasmaUpgradableExchange {
    function sellRate2Key(uint amountToReceive) external view returns (uint);
    function returnTokensBackToExchange(uint amountOfTokensToReturn) external;
    function getMore2KeyTokensForRebalancing(uint amountOfTokensRequested) external;
}