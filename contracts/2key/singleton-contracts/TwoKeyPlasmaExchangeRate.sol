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
    ITwoKeyPlasmaExchangeRateStorage public PROXY_STORAGE_CONTRACT;

    string constant _bytesToRate = "bytesToRate";

    // Contract initialization
    function setInitialParams(address _twoKeyPlasmaSingletonRegistry, address _proxyStorage) public{
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
        // Returns address of contract with given name
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
        // Inline assembly that turns string into bytes32 format
        assembly {
            result := mload(add(source, 32))
        }
    }


    /**
     * @notice       Function that sets value for pair of currencies
     * @param        name is a name of the pair of currencies you want to set value for
    */
    function setPairValue(bytes32 name, uint value) external onlyMaintainer {
        // Sets value for given currency pair
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_bytesToRate, name), value);
    }

    /**
     * @notice       Function that sets values for multiple pairs of values
     */
    function setPairValues(bytes32 [] names, uint [] values) external onlyMaintainer {
        uint length = names.length;
        // For loop that sets values for array of currency pairs
        for(uint i = 0; i < length; i++){
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_bytesToRate, names[i]), values[i]);
        }
    }

    /**
     * @notice      Function that returns value for the given pair name
     */
    function getPairValue(string name) external view returns (uint) {
        // Gets value for given currency pair key
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_bytesToRate, stringToBytes32(name)));
    }

    /**
     * @notice       Function that returns array of values for given array of pair names
     */
    function getPairValues(bytes32 [] names) external view returns (uint[]) {
        uint [] memory values = new uint[](names.length);
        // For loop that gets array of values for given currency pairs array
        for(uint i = 0; i < names.length; i++){
            values[i] = PROXY_STORAGE_CONTRACT.getUint(keccak256(_bytesToRate, names[i]));
        }

        return values;
    }
}
