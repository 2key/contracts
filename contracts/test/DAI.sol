pragma solidity ^0.4.24;

import "../2key/ERC20/StandardTokenModified.sol";

contract DAI is StandardTokenModified{
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor () public {
        name = "DAI";
        symbol = "DAI";

        decimals = 18;
        totalSupply_= 100000000*(10**18); // 1B tokens total minted supply
        address deployer = address(0xb3fa520368f2df7bed4df5185101f303f6c7decc);
        balances[deployer]= totalSupply_;
    }
}



