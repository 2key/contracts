pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './TwoKeyEconomy.sol';
import './TwoKeyEventSource.sol';
import './Call.sol';

contract TwoKeyReg is Ownable {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;
  // plasma address => ethereum address
  // note that more than one plasma address can point to the same ethereum address so it is not critical to use the same plasma address all the time for the same user
  // in some cases the plasma address will be the same as the ethereum address and in that case it is not necessary to have an entry
  // the way to know if an address is a plasma address is to look it up in this mapping
  mapping(address => address) public plasma2ethereum;
  mapping(address => address) public ethereum2plasma;
  mapping(address => bytes) public notes;

  event UserNameChanged(address owner, string name);

  TwoKeyEventSource eventSource;

  // Initialize all the constants
  constructor(TwoKeyEventSource _eventSource) public {
    eventSource = _eventSource;
    plasma2ethereum[owner] = owner;
    ethereum2plasma[owner] = owner;
  }

  function addNameInternal(string _name, address _sender) private {
    // check if name is taken
    require(name2owner[keccak256(abi.encodePacked(_name))] == 0 || name2owner[keccak256(abi.encodePacked(_name))] == _sender, "name already assigned");

    // remove previous name
    bytes memory last_name = bytes(owner2name[_sender]);
    if (last_name.length != 0) {
      name2owner[keccak256(abi.encodePacked(owner2name[_sender]))] = 0;
    }
    owner2name[_sender] = _name;
    name2owner[keccak256(abi.encodePacked(_name))] = _sender;
    emit UserNameChanged(_sender, _name);
  }

  function addName(string _name, address _sender) onlyOwner public {
    addNameInternal(_name, _sender);
  }

  function addNameByUser(string _name) public {
    addNameInternal(_name, msg.sender);
  }

  function setNote(bytes note) public {
    // note is a message you can store with sig. For example it could be the secret you used encrypted by you
    notes[msg.sender] = note;
  }

  function addPlasma2Ethereum(bytes sig) public {
    address eth_address = msg.sender;
      // add an entry connecting msg.sender to the ethereum address that was used to sign sig.
      // see setup_demo.js on how to generate sig
    bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum address")),keccak256(abi.encodePacked(eth_address))));
    require (sig.length == 65, 'bad ethereum signature length');
    address plasma_address = Call.recoverHash(hash,sig,0);
    require(plasma2ethereum[plasma_address] == address(0) || plasma2ethereum[plasma_address] == eth_address, "cant change eth=>plasma");
    plasma2ethereum[plasma_address] = eth_address;
    ethereum2plasma[eth_address] = plasma_address;
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }
}
