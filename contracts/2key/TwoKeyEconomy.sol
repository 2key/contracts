pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./RBACWithAdmin.sol";
import "./TwoKeyAdmin.sol";


contract TwoKeyEconomy is RBACWithAdmin, StandardToken, Ownable {
  string public name = 'TwoKeyEconomy';
  string public symbol= '2Key';
  uint8 public decimals= 18;

  constructor (address _twoKeyAdmin) RBACWithAdmin(_twoKeyAdmin) Ownable() public {
 		require(_twoKeyAdmin != address(0));
    TwoKeyAdmin admin ;
    admin = TwoKeyAdmin(_twoKeyAdmin);
    totalSupply_= 1000000000000000000000000;
    balances[_twoKeyAdmin] = totalSupply_;
    admin.setTwoKeyEconomy(address(this));
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch token name
  /// @return Token name as type string
  function getTokenName() public view returns(string) {
    return name;
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch token symbol
  /// @return Token symbol as type string
  function getTokenSymbol() public view returns(string) {
    return symbol;
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch decimal value of token
  /// @return Token decimal as type uint8
  function getTokenDecimals() public view returns(uint8) {
    return decimals;
  }
}
