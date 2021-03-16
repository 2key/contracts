pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateStorage.sol";

/**
  * @author Marko Lazic
 */
contract TwoKeyPlasmaExchangeRateContract is Upgradeable {

    //TODO: Integrate MAINTAINER PATTERN
    //TODO: Setters can be called only by maintainers
    bool initialized;
    address owner;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyExchangeRateStorage PROXY_STORAGE_CONTRACT;

    string constant _bytesToRate = "bytesToRate";

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    constructor (address _owner) public {
        owner = _owner;
    }

    function setInitialParams(address _twoKeyPlasmaSingletonRegistry, address _proxyStorage) public {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaExchangeRateStorage(_proxyStorage);

        initialized = true;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result){
        bytes memory tempEmptyStringTest = bytes(source);
        if(tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function setPairValue(bytes32 name, uint value) external onlyOwner {
        bytes32 key = keccak256(_bytesToRate, name);
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }

    function setPairValues(bytes32 [] names, uint [] values) external onlyOwner {
        uint length = names.length;
        for(uint i = 0; i < length; i++){
            bytes32 key = keccak256(_bytesToRate, names[i]);
            PROXY_STORAGE_CONTRACT.setUint(key, values[i]);
        }
    }

    function getPairValue(string name) external view returns (uint) {
        bytes32 hexedName = stringToBytes32(name);
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_bytesToRate, hexedName));
    }

    function getPairValues(bytes32 [] names) external view returns (uint[]) {
        uint [] memory values = new uint[](names.length);

        for(uint i = 0; i < names.length; i++){
            bytes32 key = keccak256(_bytesToRate, names[i]);
            values[i] = PROXY_STORAGE_CONTRACT.getUint(key);
        }

        return values;
    }
}
