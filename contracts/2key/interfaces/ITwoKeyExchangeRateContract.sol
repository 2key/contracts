pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 */
contract ITwoKeyExchangeRateContract {
    function getBaseToTargetRate(string _currency) public view returns (uint);
    function getStableCoinTo2KEYQuota(uint amountStableCoins, address stableCoinAddress) public view returns (uint);
}
