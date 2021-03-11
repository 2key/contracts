pragma solidity ^0.4.24;
/*
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateContractStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../upgradability/Upgradeable.sol";
*/import "../libraries/SafeMath.sol";/*
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
*/
/*
 * @author Marko Lazic
 */

contract TwoKeyPlasmaExchangeRateContract{

    using SafeMath for uint;

    //mapping(address => uint) public balance;

    address owner;
    string constant _currencyName2rate = "currencyName2rate";
    string constant _twoKeyEventSource = "TwoKeyEventSource";

    uint[] _rates;

    address TWO_KEY_SINGLETON_REGISTRY;
    address PROXY_STORAGE_CONTRACT;
    bool initialized;

    event getAddressFromKeySingletonRegistry();

    modifier onlyMaintainer(){
        require(owner == msg.sender);
        _;
    }

    function initialization(address _twoKeySingletonsRegistry, address _proxyStorage) external {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonsRegistry;
        PROXY_STORAGE_CONTRACT = _proxyStorage;

        initialized = true;
    }

    function setRate(bytes32 baseToTarget, uint rate) public onlyMaintainer{
        storeRate(baseToTarget, rate);
        address teoKeyEventSource = getAddressFromKeySingletonRegistry();
    }
    function setRates(bytes32 [] baseToTarget, uint [] rates){
        uint numberOfRates = _rates.length;
        for(uint i = 0; i < numberOfRates; i++){
            storeRate(baseToTarget, _rates[i]);
            address teoKeyEventSource = getAddressFromKeySingletonRegistry();
        }
    }
    function storeRate(bytes32 baseToTarget, uint rate) public onlyMaintainer{
        bytes32 hashKey = keccak256(baseToTarget, rate);
        PROXY_STORAGE_CONTRACT.setUint(hashKey);
    }
    function getRate(string baseToTarget){
        //return _rate[baseToTarget];
    }
    function getRates(bytes32 [] baseToTargets){
        //for(uint i; i<rate)
    }

    function stringToBytes32(string memory source) internal returns (bytes32 result){
        bytes memory tempEmptyStringTest = bytes(source);
        if(tempEmptyStringTest.length == 0){
            return 0x0;
        }
        assembly { result :=mload(add(source, 32)) }
    }

    function concat(string a, string b) internal pure returns (string){
        return string(abi.encodePacked(a,b));
    }
}