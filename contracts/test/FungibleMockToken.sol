pragma solidity ^0.4.24;

import "../2key/singleton-contracts/StandardTokenModified.sol";

/**
 * @author Nikola Madjarevic
 * @title Mock token ERC20 which will be used as token sold to improve tests over Acquisition campaigns
 */
contract FungibleMockToken is StandardTokenModified {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string _name, string _symbol, address _owner) public {
        name = _name;
        symbol = _symbol;

        decimals = 18;
        totalSupply_= 1000000000000000000000000000; // 1B tokens total minted supply
        balances[_owner]= totalSupply_;
    }


}
