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
    event RateUpdated(uint256 _currency, uint256 oldRate, uint256 oldDecimal, uint256 newRate, uint256 newDecimal, address _updater);

    mapping(uint256 => CurrencyInfo) public priceByCurrencyType;

    struct CurrencyInfo{
        uint rate;
        uint decimals;
    }

    //So'll be synced with the backend
    enum CurrencyType { USD, BTC, ETH, DAI, USDT, TUSD, EUR, JPY, GBP, TWOKEY}
    enum RatesArrayRole {CURRENCY, NUMBEROFDECIMALS, RATE}

    /**
     * @notice public mapping which will store rate between 1 wei eth and 1 wei fiat currency
     * Will be updated every 8 hours, and it's public
     */

    mapping(bytes32 => FiatCurrency) public currencyName2rate;

    struct FiatCurrency {
        uint rateEth; // this is representing rate between eth and some currency where will be 1 unit to X units depending on more valuable curr
        bool isGreater; //Flag which represent if 1 ETH > 1 fiat (ex. 1eth = 120euros) true (1eth = 0.001 X) false
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

    //input:
    //[currency1, decimals1, rate1, currency2, decimals2, rate2,..., currency3, decimal3, rate3]
    function updatePrices(uint[] _ratesArray) public onlyMaintainer {
        require(
            _ratesArray.length % 3 == 0,
            "Array should be % 3 == 0 for currency, decimals, rate."
        );

        uint rateHolder;
        uint decimalsHolder;
        CurrencyType currencyHolder;

        //each currency contains 3 values: [currencyType, numberOfDecimals, Rate] so each loop i+=3
        for(uint i = 0; i < uint(_ratesArray.length); i=i+3){

            rateHolder = _ratesArray[i + uint(RatesArrayRole.RATE)];
            decimalsHolder = _ratesArray[i + uint(RatesArrayRole.NUMBEROFDECIMALS)];
            currencyHolder = CurrencyType(_ratesArray[i]);

            CurrencyInfo memory currencyInfoHolder = CurrencyInfo({rate: rateHolder,decimals: decimalsHolder});

            emit RateUpdated(uint256(currencyHolder), priceByCurrencyType[uint256(currencyHolder)].rate,priceByCurrencyType[uint256(currencyHolder)].decimals, rateHolder,decimalsHolder, msg.sender);

            //Set currency->currencyInfo struct
            priceByCurrencyType[uint(currencyHolder)]= currencyInfoHolder;
        }
    }


    //In case 1 btc equal 7142
    //output = getRate(usd,btc) output[1]/output[0] = 7142
    //output = getRate(btc,usd) output[1]/output[0] = 0.00014

    function getRate(uint _from,uint _to) public view returns (uint, uint){
        CurrencyInfo memory baseCurrency = priceByCurrencyType[_from];
        CurrencyInfo memory targetCurrency = priceByCurrencyType[_to];

        uint baseDecimals = baseCurrency.decimals;
        uint targetDecimals = targetCurrency.decimals;

        uint targetRate;
        uint baseRate;

        if (baseDecimals > targetDecimals){
            targetRate = (10**(baseDecimals - targetDecimals)) * targetCurrency.rate;
            baseRate = baseCurrency.rate;
        }
        else if(baseDecimals < targetDecimals){
            baseRate = (10**(targetDecimals - baseDecimals)) * baseCurrency.rate;
            targetRate = targetCurrency.rate;
        }
        else{
            baseRate = baseCurrency.rate;
            targetRate = targetCurrency.rate;
        }
        return (baseRate, targetRate);
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
        /**
         * given:  1 ETH == 119.45678 USD ==>
         * then it holds:   1 * 10^18 ETH_WEI ==  119.45678 * 10^18 USD_WEI
         * it also holds:  1 ETH = 119.45678 * 10^18 USD_WEI  (iff ETH _isGreater than USD)
         * so backend will update on the rate of 1 (greater than currency) == X (the updated value) in the (lesser than currency in WEI)
         * so in the example above, the backend will send the following request:
         * setFiatCurrencyDetails("USD",true,119456780000000000000)
         */
        FiatCurrency memory f = FiatCurrency ({
            rateEth: _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit,
            isGreater: _isETHGreaterThanCurrency,
            timeUpdated: block.timestamp,
            maintainerWhoUpdated: msg.sender
            });
        currencyName2rate[_currency] = f;
        emit PriceUpdated(_currency, _RateFromOneGreaterThanUnitInWeiOfLesserThanUnit, block.timestamp, msg.sender);
    }

    /**
     * @notice Function to get price for the selected currency
     * @param _currency is the currency (ex. 'USD', 'EUR', etc.)
     * @return rate between currency and eth wei
     */
    function getFiatCurrencyDetails(
        string _currency
    )
    public
    view
    returns (uint,bool,uint,address)
    {
        bytes32 key = stringToBytes32(_currency);
        return (
        currencyName2rate[key].rateEth,
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
