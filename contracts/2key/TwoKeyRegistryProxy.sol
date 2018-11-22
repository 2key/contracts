pragma solidity ^0.4.24;

import "./TwoKeyRegistryStorage.sol";

contract TwoKeyRegistryProxy is TwoKeyRegistryStorage {

    // Logic contract
    address public logic_contract;

    //TODO Add modifiers - ownable or something like that
    function setLogicContract(address _logicContractAddress) public returns (bool) {
        logic_contract = _logicContractAddress;
        return true;
    }

    //Fallback function
    function () payable public {
        address target = logic_contract;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            case 1 { return(ptr, size) }
        }
    }
}
