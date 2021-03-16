pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateContractStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../upgradability/Upgradeable.sol";
import "../libraries/SafeMath.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";

/*
 * @author Marko Lazic
 */

// TODO: General practice is to name file same as contract.
contract TwoKeyPlasmaExchangeRateContract{

    // TODO: Where did we spec that contract will have owner?
    // TODO: Since this is contract receiving calls from proxy, nothing but constants should be explictly declared
    address owner = msg.sender;
    string constant _currencyName2rate = "currencyName2rate";
    string constant _twoKeyEventSource = "TwoKeyEventSource";
    bool initialized;

    address TWO_KEY_SINGLETON_REGISTRY;
    address PROXY_STORAGE_CONTRACT; // TODO: This should be instantiated as ITwoKeyPlasmaExchangeRateStorage

    modifier onlyMaintainer() { //TODO: How come owner is maintainer?
        require(owner == msg.sender);
        _;
    }

    //ITwoKeyExchangeRateContractStorage public PROXY_STORAGE_CONTRACT;
    function setInitialParams(address _twoKeySingletonesRegistry, address _proxyStorage) external {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = _proxyStorage;

        initialized = true;
    }

    function setFiatCurrencyDetails(bytes32 _currency, uint _baseToTargetRate) public onlyMaintainer {
        storeFiatCurrencyDetails(_currency, _baseToTargetRate);
        address twoKeyEventSource = getAddressFromKeySingletonRegistry(_twoKeyEventSource); //TODO: What is this line doing?
    }

    function setMultipleFiatCurrencyDetails(bytes32[] _currencies, uint[] _baseToTargetRates) public onlyMaintainer {
        uint numberOfFiats = _currencies.length;
        for(uint i = 0; i < numberOfFiats; i++) {
            storeFiatCurrencyDetails(_currencies[i], _baseToTargetRates[i]);
            address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
            ITwoKeyEventSourceEvents(twoKeyEventSource); //TODO: What is this line doing?
            ITwoKeyEventSourceEvents(twoKeyEventSource).priceUpdated(_currencies[i], _baseToTargetRates[i], block.timestamp, msg.sender); //TODO: What is this line doing?
        }
    }

    function storeFiatCurrencyDetails(bytes32 _currency, uint _baseToTargetRate) internal {
        bytes32 hashKey = keccak256(_currencyName2rate, _currency);
        PROXY_STORAGE_CONTRACT.setUint(hashKey, _baseToTargetRate);
    }

    function getBaseToTargetRate(string base_target) public view returns (uint) {
        bytes32 hexedBaseTarget = stringToBytes32(base_target);
        return getBaseToTargetRateInternal(hexedBaseTarget);
    }

    function getBaseToTargetRateInternal(bytes32 baseTarget) internal view returns (uint) {
        bytes32 keyHash = keccak256(_currencyName2rate, baseTarget);
        return PROXY_STORAGE_CONTRACT.getUint(keyHash);
    }

    function exchangeCurrencies(string base_target, uint base_amount) public view returns (uint) {
        return getBaseToTargetRate(base_target).mul(base_amount);
    }

    //TODO: Where did we spec this function
    function getFiatToStableQuotes(uint amountInFiatWei, string fiatCurrency, bytes32 [] stableCoinPairs) public view returns (uint[]) {
        uint len = stableCoinPairs.length;
        uint [] memory pairs = new uint[](len);
        uint i;
        for(i = 0; i < len; i++) {
            uint rate = getBaseToTargetRateInternal(stableCoinPairs[i]);
            pairs[i] = amountInFiatWei.mul(10**18).div(rate);
        }
        return pairs;
    }

    //TODO: Where did we spec this function
    function getStableCoinToUSDQuota(address stableCoinAddress) public view returns (uint){
        string memory tokenSymbol = IERC20(stableCoinAddress).symbol();
        if(getNonUpgradableContractAddressFromTwoKetSingletonRegistry(tokenSymbol) == stableCoinAddress) {
            string memory tokenSymbolToCurrency = concatenateStrings(tokenSymbol, "-USD");
        }
        return 0;
    }


    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result :=mload(add(source, 32))
        }
    }

    //TODO: Do you use this function anywhere?
    function concatenateStrings(string a, string b) internal pure returns (string) {
        return string(abi.encodePacked(a,b));
    }
}
