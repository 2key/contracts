pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../singleton-storage-contracts/TwoKeyPlasmaExchangeRateStorage.sol";
import "../interfaces/storage-contracts/ITwoKeyExchangeRateStorage.sol";

/**
  * @author Marko Lazic
  */

contract TwoKeyPlasmaExchangeRateContract is Upgradeable{

    address owner;
    bool initialized;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaExchangeRateStorage PROXY_STORAGE_CONTRACT;
    bytes32 key = stringToBytes32("bytesToRate");

    modifier onlyOwner{
        require(owner == msg.sender);
        _;
    }

    mapping(bytes32 => uint) public baseToTargetRate;

    constructor (address _owner, uint _balance) public {
        owner = _owner;
    }

    function setInitialParams(address _twoKeyPlasmaSingletonRegistry, address _proxyStorage) public {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaFactoryStorage(_proxyStorage);

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
        //baseToTargetRate[name] = value;
        PROXY_STORAGE_CONTRACT.setUint(keccak256(key, name), value);
    }

    function setPairValues(bytes32 [] names, uint [] values) external onlyOwner {
        uint length = names.length;
        for(uint i = 0; i < length; i++){
            PROXY_STORAGE_CONTRACT.setUintArray(keccak256(key, names[i]), values[i]);
        }
    }

    function getPairValues(bytes32 [] names) external view returns (uint[]) {
        uint [] memory values = new uint[](names.length);
        for(uint i = 0; i < names.length; i++){
            values[i] = PROXY_STORAGE_CONTRACT.getUintArray(keccak256(key, names[i]));
        }
        return values;
    }
}
