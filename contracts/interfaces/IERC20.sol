pragma solidity ^0.4.24;

/// Interface of ERC20 contract we need in order to invoke balanceOf method from another contracts
contract IERC20 {
    function balanceOf(address whom) view public returns (uint);
    function transfer(address _to, uint256 _value) public returns (bool);
    function decimals() view public returns (uint8);
    function symbol() view public returns (string);
    function getName() view public returns (string);
}
