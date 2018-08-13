pragma solidity ^0.4.24;

import './openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ERC20full is StandardToken {
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
  function decimals() public view returns (uint8);
}
