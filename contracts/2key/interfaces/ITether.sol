pragma solidity ^0.4.0;

contract ITether {
    function transferFrom(address _from, address _to, uint256 _value) external;

    function transfer(address _to, uint256 _value) external;
}
