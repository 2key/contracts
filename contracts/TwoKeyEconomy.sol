pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

contract TwoKeyEconomy is MintableToken {
  string public name = 'TwoKeyEconomy';
  string public symbol = '2KE';
  uint8 public decimals = 18;
  uint public INITIAL_SUPPLY = 1000000000000000000000000000;

  function TwoKeyEconomy() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}