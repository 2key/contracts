pragma solidity ^0.4.24;

import './ownership/Ownable.sol';

contract TwoKeyReg is Ownable {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;



  function addName(string _name, address _sender) onlyOwner public {
    // check if name is taken
    if (name2owner[keccak256(abi.encodePacked(_name))] != 0) {
      revert();
    }
    // remove previous name
    bytes memory last_name = bytes(owner2name[_sender]);
    if (last_name.length != 0) {
      name2owner[keccak256(abi.encodePacked(owner2name[_sender]))] = 0;
    }
    owner2name[_sender] = _name;
    name2owner[keccak256(abi.encodePacked(_name))] = _sender;
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }

}
