pragma solidity ^0.4.24;

contract ITwoKeyTest1 {
  function test1() public;
}
contract TwoKeyTest2 {
  event Log1(string s, uint256 units);
  event Log1A(string s, address a);
  event Log1B32(string s, bytes32 b32);
  address test1;

  function setTest1(address _test1) public {
    test1 = _test1;
  }

  function test2() public {
    emit Log1A("test2", msg.sender);
    ITwoKeyTest1(test1).test1();
  }
}

contract TwoKeyTest1 {
  event Log1(string s, uint256 units);
  event Log1A(string s, address a);
  event Log1B32(string s, bytes32 b32);

  function test1() public {
    emit Log1A("test1", msg.sender);
  }
}
