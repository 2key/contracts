pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateContractStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../upgradability/Upgradeable.sol";
import "../libraries/SafeMath.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "../interfaces/IUniswapV2Router02.sol";


/**
 * @author Nikola Madjarevic
 */
contract TwoKeyExchangeRateContract is Upgradeable, ITwoKeySingletonUtils {

    /**
     * Storage keys are stored on the top. Here they are in order to avoid any typos
     */
    string constant _currencyName2rate = "currencyName2rate";
    string constant _pairToOracleAddress = "pairToOracleAddress";
    string constant _twoKeyEventSource = "TwoKeyEventSource";

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
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
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
            address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
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
        bytes32 hashKey = keccak256(_currencyName2rate, _currency);
        PROXY_STORAGE_CONTRACT.setUint(hashKey, _baseToTargetRate);
    }


    /**
     * @notice Function to set ChainLink oracle addresses
     * @param  priceFeeds is the array of price feeds ChainLink contract addresses
     * @param  hexedPairs is the array of pairs hexed
     */
    function storeChainLinkOracleAddresses(
        bytes32 [] hexedPairs,
        address [] priceFeeds
    )
    public
    onlyMaintainer
    {
        uint i;

        for(i = 0; i < priceFeeds.length; i++) {
            PROXY_STORAGE_CONTRACT.setAddress(
                keccak256(_pairToOracleAddress, hexedPairs[i]),
                priceFeeds[i]
            );
        }
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
        bytes32 hexedBaseTarget = stringToBytes32(base_target);
        return getBaseToTargetRateInternal(hexedBaseTarget);
    }


    function getBaseToTargetRateInternal(
        bytes32 baseTarget
    )
    internal
    view
    returns (uint)
    {
        address oracleAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_pairToOracleAddress, baseTarget));
        int latestPrice = getLatestPrice(oracleAddress);
        uint8 decimalsPrecision = getDecimalsReturnPrecision(oracleAddress);
        uint maxDecimals = 18;
        return uint(latestPrice) * (10**(maxDecimals.sub(decimalsPrecision))); //do sub instead of -
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



    function getFiatToStableQuotes(
        uint amountInFiatWei,
        string fiatCurrency,
        bytes32 [] stableCoinPairs //Pairs stable coin - ETh
    )
    public
    view
    returns (uint[])
    {
        uint len = stableCoinPairs.length;

        uint [] memory pairs = new uint[](len);

        uint i;

        // We have rate 1 DAI = X USD => 1 USD = 1/X DAI
        // We need to compute N dai = Y usd
        for(i = 0; i < len; i++) {
            // This represents us how much USD is 1 stable coin unit worth
            // Example: 1 DAI = rate = 0.99 $
            // 1 * DAI = 0.99 * USD
            // 1 USD = 1 * DAI / 0.99
            // 15 USD = 15 / 0.99

            // get rate against ETH (1 STABLE  = rate ETH)
            uint stableEthRate = getBaseToTargetRateInternal(stableCoinPairs[i]);

            // This is the ETH/USD rate
            uint eth_usd = getBaseToTargetRateInternal(stringToBytes32("USD"));

            uint rate =  stableEthRate.mul(eth_usd).div(10**18);

            pairs[i] = amountInFiatWei.mul(10**18).div(rate);
        }

        return pairs;
    }

    /**
     * @notice          Function to fetch 2KEY against DAI rate from uniswap
     */
    function get2KeyDaiRate()
    public
    view
    returns (uint)
    {
        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        address [] memory path = new address[](2);

        path[0] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        path[1] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI");

        uint[] memory amountsOut = new uint[](2);

        amountsOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            10**18,
            path
        );

        return amountsOut[1];
    }

    function getStableCoinToUSDQuota(
        address stableCoinAddress
    )
    public
    view
    returns (uint)
    {
        // Take the symbol of the token
        string memory tokenSymbol = IERC20(stableCoinAddress).symbol();
        // Check that this symbol is matching address stored in our codebase so we are sure that it's real asset
        if(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(tokenSymbol) == stableCoinAddress) {
            // Chainlink provides us with the rates from StableCoin -> ETH, and along with that we have ETH -> USD quota

            // Generate pair against ETH (Example: Symbol = DAI ==> result = 'DAI-ETH'
            string memory tokenSymbolToCurrency = concatenateStrings(tokenSymbol, "-ETH");

            // get rate against ETH (1 STABLE  = rate ETH)
            uint stableEthRate = getBaseToTargetRateInternal(stringToBytes32(tokenSymbolToCurrency));

            // This is the ETH/USD rate
            uint eth_usd = getBaseToTargetRateInternal(stringToBytes32("USD"));

            return stableEthRate.mul(eth_usd).div(10**18);
        }
        // If stable coin is not matched, return 0 as quota
        return 0;
    }

    /**
     * @notice          Function to fetch the latest token price from ChainLink oracle
     * @param           oracleAddress is the address of oracle we fetch price from
     */
    function getLatestPrice(
        address oracleAddress
    ) public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(oracleAddress).latestRoundData();
        return price;
    }


    /**
     * @notice          Function to fetch on how many decimals is the response
     * @param           oracleAddress is the address of the oracle from which we take price
     */
    function getDecimalsReturnPrecision(
        address oracleAddress
    )
    public
    view
    returns (uint8)
    {
        return AggregatorV3Interface(oracleAddress).decimals();
    }

    /**
     * @notice          Function to fetch address of the oracle for the specific pair
     * @param           pair is the name of the pair for which we store oracles
     */
    function getChainLinkOracleAddress(
        string memory pair
    )
    public
    view
    returns (address)
    {
        bytes32 hexedPair = stringToBytes32(pair);
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_pairToOracleAddress, hexedPair));
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


    function concatenateStrings(
        string a,
        string b
    )
    internal
    pure
    returns (string)
    {
        return string(abi.encodePacked(a,b));
    }
}
