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


    function setExchangeRate(
        bytes32 _currency,
        uint baseToTargetRate,
        address maintainer
    )
    external
    {

    }

}
