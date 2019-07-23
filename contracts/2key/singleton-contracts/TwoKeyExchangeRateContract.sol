pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateContractStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../upgradability/Upgradeable.sol";
import "./ITwoKeySingletonUtils.sol";
import "../libraries/SafeMath.sol";


/**
 * @author Nikola Madjarevic
 */
contract TwoKeyExchangeRateContract is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint;
    bool initialized;

    ITwoKeyExchangeRateContractStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function which will be called immediately after contract deployment
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy storage contract
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyExchangeRateContractStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice Backend calls to update rates
     * @dev only twoKeyMaintainer address will be eligible to update it
     * @param _currency is the bytes32 (hex) representation of currency shortcut string
     * @param _baseToTargetRate is the rate between base and target currency
     */
    function setFiatCurrencyDetails(
        bytes32 _currency,
        uint _baseToTargetRate
    )
    public
    onlyMaintainer
    {
        storeFiatCurrencyDetails(_currency, _baseToTargetRate);
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource");
        ITwoKeyEventSourceEvents(twoKeyEventSource).priceUpdated(_currency, _baseToTargetRate, block.timestamp, msg.sender);
    }

    /**
     * @notice Function to update multiple rates at once
     * @param _currencies is the array of currencies
     * @dev Only maintainer can call this
     */
    function setMultipleFiatCurrencyDetails(
        bytes32[] _currencies,
        uint[] _baseToTargetRates
    )
    public
    onlyMaintainer
    {
        uint numberOfFiats = _currencies.length; //either _isETHGreaterThanCurrencies.length
        //There's no need for validation of input, because only we can call this and that costs gas
        for(uint i=0; i<numberOfFiats; i++) {
            storeFiatCurrencyDetails(_currencies[i], _baseToTargetRates[i]);
            address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource");
            ITwoKeyEventSourceEvents(twoKeyEventSource).priceUpdated(_currencies[i], _baseToTargetRates[i], block.timestamp, msg.sender);
        }
    }

    /**
     * @notice Function to store details about currency
     * @param _currency is the bytes32 (hex) representation of currency shortcut string
     * @param _baseToTargetRate is the rate between base and target currency
     */
    function storeFiatCurrencyDetails(
        bytes32 _currency,
        uint _baseToTargetRate
    )
    internal
    {
        bytes32 hashKey = keccak256("currencyName2rate", _currency);
        PROXY_STORAGE_CONTRACT.setUint(hashKey, _baseToTargetRate);
    }


    /**
     * @notice Function getter for base to target rate
     * @param base_target is the name of the currency
     */
    function getBaseToTargetRate(
        string base_target
    )
    public
    view
    returns (uint)
    {
        bytes32 key = stringToBytes32(base_target);
        bytes32 hashKey = keccak256("currencyName2rate", key);
        return PROXY_STORAGE_CONTRACT.getUint(hashKey);
    }


    /**
     * @notice Helper calculation function
     */
    function exchangeCurrencies(
        string base_target,
        uint base_amount
    )
    public
    view
    returns (uint)
    {
        return getBaseToTargetRate(base_target).mul(base_amount);
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
