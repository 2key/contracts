pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 * @notice Interface for exchange contract to get the eth-currency rate
 */
contract ITwoKeyExchangeContract {
    function getFiatCurrencyDetails(string _currency) public view returns (uint,bool);
}
