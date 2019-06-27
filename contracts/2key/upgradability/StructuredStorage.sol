pragma solidity ^0.4.0;

import "./Upgradeable.sol";

contract StructuredStorage is Upgradeable {

    bool initialized;

    address public PROXY_LOGIC_CONTRACT;
    address public DEPLOYER;

    mapping(bytes32 => bytes32) bytes32Storage;
    mapping(bytes32 => uint) uIntStorage;
    mapping(bytes32 => string) stringStorage;
    mapping(bytes32 => address) addressStorage;
    mapping(bytes32 => bytes) bytesStorage;
    mapping(bytes32 => bool) boolStorage;
    mapping(bytes32 => int) intStorage;
    //TODO I would add also arrays of everything by default, with default accessors specialising in fetching arrays or subarrays etc..


    modifier onlyDeployer {
        require(msg.sender == DEPLOYER);
        _;
    }

    modifier onlyProxyLogicContract {
        require(msg.sender == PROXY_LOGIC_CONTRACT);
        _;
    }

    // *** Setter for Contract which holds all the logic ***
    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address deployer) external {
        require(initialized == false);

        PROXY_LOGIC_CONTRACT = _proxyLogicContract;
        DEPLOYER = deployer;

        initialized = true;
    }

    function setProxyLogicContract(address _proxyLogicContract) external onlyDeployer {
        //TODO this is done on upgrades of the logic? perhaps it would be better to mark only registry and have the registry do this from a single call to update the logic for a singleton
        PROXY_LOGIC_CONTRACT = _proxyLogicContract;
    }

    // *** Getter Methods ***
    function getUint(bytes32 _key) onlyProxyLogicContract external view returns (uint) {
        return uIntStorage[_key];
    }

    function getString(bytes32 _key) onlyProxyLogicContract external view returns(string) {
        return stringStorage[_key];
    }

    function getAddress(bytes32 _key) onlyProxyLogicContract external view returns(address) {
        return addressStorage[_key];
    }

    function getBytes(bytes32 _key) onlyProxyLogicContract external view returns(bytes) {
        return bytesStorage[_key];
    }

    function getBool(bytes32 _key) onlyProxyLogicContract external view returns(bool) {
        return boolStorage[_key];
    }

    function getInt(bytes32 _key) onlyProxyLogicContract external view returns(int) {
        return intStorage[_key];
    }

    function getBytes32(bytes32 _key) onlyProxyLogicContract external view returns (bytes32) {
        return bytes32Storage[_key];
    }

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) onlyProxyLogicContract external {
        uIntStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value) onlyProxyLogicContract external {
        stringStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) onlyProxyLogicContract external {
        addressStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value) onlyProxyLogicContract external {
        bytesStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) onlyProxyLogicContract external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value) onlyProxyLogicContract external {
        intStorage[_key] = _value;
    }

    function setBytes32(bytes32 _key, bytes32 _value) onlyProxyLogicContract external {
        bytes32Storage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) onlyProxyLogicContract external {
        delete uIntStorage[_key];
    }

    function deleteString(bytes32 _key) onlyProxyLogicContract external {
        delete stringStorage[_key];
    }

    function deleteAddress(bytes32 _key) onlyProxyLogicContract external {
        delete addressStorage[_key];
    }

    function deleteBytes(bytes32 _key) onlyProxyLogicContract external {
        delete bytesStorage[_key];
    }

    function deleteBool(bytes32 _key) onlyProxyLogicContract external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key) onlyProxyLogicContract external {
        delete intStorage[_key];
    }

    function deleteBytes32(bytes32 _key) onlyProxyLogicContract external {
        delete bytes32Storage[_key];
    }
}
