pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry =
        ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
        _;
    }

    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }
}
