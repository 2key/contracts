pragma solidity ^0.4.24;

import "./TwoKeyRegistryStorage.sol";

contract TwoKeyRegistry is TwoKeyRegistryStorage {

    // Logic contract
    address public logic_contract;

    //TODO Add modifiers - ownable or something like that
    function setLogicContract(address _logicContractAddress) public returns (bool) {
        logic_contract = _logicContractAddress;
        return true;
    }

    // fall back function
    function () payable public {

        address target = logic_contract;

        assembly {
        // Copy the data sent to the memory address starting free mem position
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

        // Proxy the call to the contract address with the provided gas and data
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)

        // Copy the data returned by the proxied call to memory
            let size := returndatasize
            returndatacopy(ptr, 0, size)

        // Check what the result is, return and revert accordingly
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}
