pragma solidity ^0.4.24;

import "../MaintainingPattern.sol";
import "../Upgradeable.sol";


/**
 * @author Nikola Madjarevic
 * This is going to be the contract on which we will store exchange rates between USD and ETH
 * Will be maintained, and updated by our trusted server and CMC api every 8 hours.
 */
contract TwoKeyExchangeRateContract is Upgradeable, MaintainingPattern {


    /**
     * @notice Event will be emitted every time we update the price for the fiat
     */
    event PriceUpdated(bytes32 _currency, uint newRate, uint _timestamp, address _updater);

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

    //TODO add function to serve clients - getExchangeRate("base/target") --> return just a value

    struct ExchangeRate {
        uint baseToTargetRate; // this is representing rate between eth and some currency where will be 1 unit to X units depending on more valuable curr
        bool isGreater; //Flag which represent if 1 ETH > 1 fiat (ex. 1eth = 120euros) true (1eth = 0.001 X) false ,  // if isGreater == True, 1 target worth more than 1 base
        uint timeUpdated;
        address maintainerWhoUpdated;
    }


    /**
     * @notice Function which will be called immediately after contract deployment
     * @param _maintainers is the array of maintainers addresses
     * @param _twoKeyAdmin is the address of TwoKeyAdmin contract
     * @dev Can be called only once
     */
    function setInitialParams(
        address [] _maintainers,
        address _twoKeyAdmin
    )
    external
    {
        require(_twoKeyAdmin != address(0)); //validation that it can be called only once
        require(twoKeyAdmin == address(0)); //validation that it can be called only once
        twoKeyAdmin = _twoKeyAdmin;
        isMaintainer[msg.sender] = true; //for truffle deployment
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function where our backend will update the state (rate between eth_wei and dollar_wei) every 8 hours
     * @dev only twoKeyMaintainer address will be eligible to update it
     * @param _currency is the bytes32 (hex) representation of currency shortcut string ('USD','EUR',etc)
     * @param _isETHGreaterThanCurrency true if 1 eth = more than 1 unit of X otherwise false
     * @param _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit 1 (greater than currency) == X (the updated value) in the (lesser than currency in WEI)
     */
    function setFiatCurrencyDetails(
        bytes32 _currency,
        bool _isETHGreaterThanCurrency,
        uint _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit
    )
    public
    onlyMaintainer
    {
        storeFiatCurrencyDetails(_currency, _isETHGreaterThanCurrency, _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit);
        emit PriceUpdated(_currency, _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit, block.timestamp, msg.sender);
    }

    /**
     * @notice Function to update multiple rates at once
     * @param _currencies is the array of currencies
     * @param _isETHGreaterThanCurrencies true if 1 eth = more than 1 unit of X otherwise false
     * @param _RatesFromOneGreaterThanUnitInWeiOfLesserThanUnit 1 (greater than currency) == X (the updated value) in the (lesser than currency in WEI)
     * @dev Only maintainer can call this
     */
    function setMultipleFiatCurrencyDetails(
        bytes32[] _currencies,
        bool[] _isETHGreaterThanCurrencies,
        uint[] _RatesFromOneGreaterThanUnitInWeiOfLesserThanUnit
    )
    public
    onlyMaintainer
    {
        uint numberOfFiats = _currencies.length; //either _isETHGreaterThanCurrencies.length
        //There's no need for validation of input, because only we can call this and that costs gas
        for(uint i=0; i<numberOfFiats; i++) {
            storeFiatCurrencyDetails(_currencies[i], _isETHGreaterThanCurrencies[i], _RatesFromOneGreaterThanUnitInWeiOfLesserThanUnit[i]);
            emit PriceUpdated(_currencies[i], _RatesFromOneGreaterThanUnitInWeiOfLesserThanUnit[i], block.timestamp, msg.sender);
        }
    }

    function storeFiatCurrencyDetails(
        bytes32 _currency,
        bool _isETHGreaterThanCurrency,
        uint _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit
    )
    internal
    {
        /**
         * given:  1 ETH == 119.45678 USD ==>
         * then it holds:   1 * 10^18 ETH_WEI ==  119.45678 * 10^18 USD_WEI
         * it also holds:  1 ETH = 119.45678 * 10^18 USD_WEI  (iff ETH _isGreater than USD)
         * so backend will update on the rate of 1 (greater than currency) == X (the updated value) in the (lesser than currency in WEI)
         * so in the example above, the backend will send the following request:
         * setFiatCurrencyDetails("USD",true,119456780000000000000)
         */
        ExchangeRate memory f = ExchangeRate({
            baseToTargetRate: _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit,
            isGreater: _isETHGreaterThanCurrency,
            timeUpdated: block.timestamp,
            maintainerWhoUpdated: msg.sender
            });
        currencyName2rate[_currency] = f;
    }

    /**
     * @notice Function to get price for the selected currency
     * @return rate between currency and eth wei
     */
    //TODO: please change params of this function, to accept BASE/TARGET pair as input, and output the final rate (do all the isGrater than considerations here in this contract, don't require this contract's clients to do that)
    function getFiatCurrencyDetails(
        string base_target
    )
    public
    view
    returns (uint,bool,uint,address)
    {
        bytes32 key = stringToBytes32(base_target);
        return (
            currencyName2rate[key].baseToTargetRate,
            currencyName2rate[key].isGreater,
            currencyName2rate[key].timeUpdated,
            currencyName2rate[key].maintainerWhoUpdated
        );
    }

    /**
     * @notice Helper method to convert string to bytes32
     * @dev If string.length > 32 then the rest after 32nd char will be deleted
     * @return result
     */
    function stringToBytes32(
        string memory source
    )
    internal
    returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

}
