pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../upgradability/Upgradeable.sol";
import "./ITwoKeySingletonUtils.sol";


/**
 * @author Nikola Madjarevic
 * This is going to be the contract on which we will store exchange rates between USD and ETH
 * Will be maintained, and updated by our trusted server and CMC api every 8 hours.
 */
contract TwoKeyExchangeRateContract is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    address public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Event will be emitted every time we update the price for the fiat
     */
    event PriceUpdated(bytes32 _currency, uint newRate, uint _timestamp, address _updater);
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

    /**
     * @notice Function which will be called immediately after contract deployment
     * @dev Can be called only once
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry
//        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;

        initialized = true;
    }


    /**
     * @notice Function where our backend will update the state (rate between eth_wei and dollar_wei) every 8 hours
     * @dev only twoKeyMaintainer address will be eligible to update it
     * @param _currency is the bytes32 (hex) representation of currency shortcut string ('USD','EUR',etc)
     */
    function setFiatCurrencyDetails(
        bytes32 _currency,
        uint baseToTargetRate
    )
    public
    {
        storeFiatCurrencyDetails(_currency, baseToTargetRate);
        emit PriceUpdated(_currency, baseToTargetRate, block.timestamp, msg.sender);
    }

    /**
     * @notice Function to update multiple rates at once
     * @param _currencies is the array of currencies
     * @dev Only maintainer can call this
     */
    function setMultipleFiatCurrencyDetails(
        bytes32[] _currencies,
        uint[] baseToTargetRates
    )
    public
    {
        uint numberOfFiats = _currencies.length; //either _isETHGreaterThanCurrencies.length
        //There's no need for validation of input, because only we can call this and that costs gas
        for(uint i=0; i<numberOfFiats; i++) {
            storeFiatCurrencyDetails(_currencies[i], baseToTargetRates[i]);
            emit PriceUpdated(_currencies[i], baseToTargetRates[i], block.timestamp, msg.sender);
        }
    }

    function storeFiatCurrencyDetails(
        bytes32 _currency,
        uint baseToTargetRate
    )
    internal
    {
        ExchangeRate memory f = ExchangeRate({
            baseToTargetRate: baseToTargetRate,
            timeUpdated: block.timestamp,
            maintainerWhoUpdated: msg.sender
            });
        currencyName2rate[_currency] = f;
    }

    /**
     * @notice Function to get price for the selected currency
     * @return rate between currency and eth wei
     */
    function getFiatCurrencyDetails(
        string base_target
    )
    public
    view
    returns (uint,uint,address)
    {
        bytes32 key = stringToBytes32(base_target);

    }

    function getBaseToTargetRate(
        string base_target
    )
    public
    view
    returns (uint)
    {
        bytes32 key = stringToBytes32(base_target);
        return currencyName2rate[key].baseToTargetRate;
    }


    /**
     * @notice Function to calculate how many
     */
    function exchangeCurrencies(
        string base_target,
        uint base_amount
    )
    public
    view
    returns (uint)
    {
        return getBaseToTargetRate(base_target) * base_amount;
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
