pragma solidity ^0.4.24;

import "../2key/singleton-contracts/TwoKeyRegistry.sol";

contract TwoKeyRegistryV1 is TwoKeyRegistry {
    function getMaintainers() public view returns (address[]) {
        address [] memory add = new address[](1);
        add[0] = 0xb47575ea1302a2c1a09d1cc6f3ed0fcf9d1678d4;
        return add;
    }
}
