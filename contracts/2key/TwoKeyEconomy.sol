pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./RBACWithAdmin.sol";
import "./TwoKeyAdmin.sol";


contract TwoKeyEconomy is RBACWithAdmin, StandardToken, Ownable {
  string public name = 'TwoKeyEconomy';
  string public symbol= '2KEY';
  uint8 public decimals= 18;

  constructor (address _twoKeyAdmin) RBACWithAdmin(_twoKeyAdmin) Ownable() public {
 		require(_twoKeyAdmin != address(0));
    TwoKeyAdmin admin = TwoKeyAdmin(_twoKeyAdmin);
    totalSupply_= 1000000000000000000000000;
    balances[_twoKeyAdmin] = totalSupply_;
  }

}
