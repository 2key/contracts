pragma solidity ^0.4.18; //We have to specify what version of compiler this code will use

contract TwoKeyReg {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;

  function addName(string _name) public {
    address _owner = msg.sender;
    // check if name is taken
    if (name2owner[keccak256(_name)] != 0) {
      revert();
    }
    // remove previous name
    bytes memory last_name = bytes(owner2name[_owner]);
    if (last_name.length != 0) {
      name2owner[keccak256(owner2name[_owner])] = 0;
    }
    owner2name[_owner] = _name;
    name2owner[keccak256(_name)] = _owner;
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(_name)];
  }
  function getOwner2Name(address _owner) public view returns (string) {
    return owner2name[_owner];
  }

  event Created(address indexed owner, address c);
  function createdContract(address _owner) public {
    address c = msg.sender;
    Created(_owner, c);
  }

  event Joined(address indexed to, address c);
  function joinedContract(address to) public {
    address c = msg.sender;
    Joined(to, c);
  }
}
