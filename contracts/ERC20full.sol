pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ERC20full is StandardToken {
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
  function decimals() public view returns (uint8);
}
