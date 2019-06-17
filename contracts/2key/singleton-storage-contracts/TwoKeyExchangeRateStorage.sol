pragma solidity ^0.4.0;

import "../upgradability/StructuredStorage.sol";

contract TwoKeyExchangeRateStorage is StructuredStorage {

    /**
     * @notice public mapping which will store rate between 1 wei eth and 1 wei fiat currency
     * Will be updated every 8 hours, and it's public
     */
    //TODO:  key methodology --> BASE/TARGET
    //TODO:  "JPY/USD" 0.002 * 10**18
    //TODO   "EUR/USD" 1.2   * 10**18
    //TODO   "GBP/USD" 4.2   * 10**18
    //TODO   "USD/DAI" 1.001 * 10**18
    //TODO   "USD" (ETH/USD)  260   * 10**18
    //TODO   "BTC" (ETH/BTC)  0.03  * 10**18
    //TODO   "DAI" (ETH/DAI)  260   * 10**18
    mapping(bytes32 => ExchangeRate) public currencyName2rate;


    struct ExchangeRate {
        uint baseToTargetRate; // this is representing rate between eth and some currency where will be 1 unit to X units depending on more valuable curr
        uint timeUpdated;
        address maintainerWhoUpdated;
    }

    function getExchangeRate(
        bytes32 key
    )
    public
    view
    returns (uint,uint,address)
    {
        return (
            currencyName2rate[key].baseToTargetRate,
            currencyName2rate[key].timeUpdated,
            currencyName2rate[key].maintainerWhoUpdated
        );
    }

}
