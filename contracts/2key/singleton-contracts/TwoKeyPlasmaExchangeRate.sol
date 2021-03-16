pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaExchangeRateStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";

/**
  * @title TwoKeyPlasmaExchangeRate contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaExchangeRateContract is Upgradeable {

    bool initialized;
    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaExchangeRateStorage PROXY_STORAGE_CONTRACT;

    string constant _bytesToRate = "bytesToRate";

    function setInitialParams(address _twoKeyPlasmaSingletonRegistry, address _proxyStorage) public onlyMaintainer{
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaExchangeRateStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice      Modifier which will be used to restrict set function calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }

    /**
     * @notice      Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }

    /**
    * @notice       Function that converts string to bytes32
    */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result){
        bytes memory tempEmptyStringTest = bytes(source);
        if(tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
    * @notice       Function that sets value for pair of currencies
    * @param        name is a name of the pair of currencies you want to set value for
    */
    function setPairValue(bytes32 name, uint value) external onlyMaintainer {
        bytes32 key = keccak256(_bytesToRate, name);
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }

    /**
    * @notice       Function that sets values for multiple pairs of values
    */
    function setPairValues(bytes32 [] names, uint [] values) external onlyMaintainer {
        uint length = names.length;
        for(uint i = 0; i < length; i++){
            bytes32 key = keccak256(_bytesToRate, names[i]);
            PROXY_STORAGE_CONTRACT.setUint(key, values[i]);
        }
    }

    /**
     * @notice      Function that returns value for the given pair name
     */
    function getPairValue(string name) external view returns (uint) {
        bytes32 hexedName = stringToBytes32(name);
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_bytesToRate, hexedName));
    }

    /**
    * @notice       Function tht returns multiple values for multiple given pair names
    */
    function getPairValues(bytes32 [] names) external view returns (uint[]) {
        uint [] memory values = new uint[](names.length);

        for(uint i = 0; i < names.length; i++){
            bytes32 key = keccak256(_bytesToRate, names[i]);
            values[i] = PROXY_STORAGE_CONTRACT.getUint(key);
        }

        return values;
    }
}
