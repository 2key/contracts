pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './TwoKeyEconomy.sol';

contract TwoKeyReg is Ownable {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;
  // plasma address => ethereum address
  // note that more than one plasma address can point to the same ethereum address so it is not critical to use the same plasma address all the time for the same user
  // in some cases the plasma address will be the same as the ethereum address and in that case it is not necessary to have an entry
  // the way to know if an address is a plasma address is to look it up in this mapping
  mapping(address => address) public plasma2ethereum;

  event UserNameChanged(address owner, string name);

  function addNameInternal(string _name, address _sender) private {
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
    emit UserNameChanged(_sender, _name);
  }

  function addName(string _name, address _sender) onlyOwner public {
    addNameInternal(_name, _sender);
  }

  function addNameByUser(string _name) public {
    addNameInternal(_name, msg.sender);
  }

  function addNameAndPlasmaByUser(string _name, bytes sig) public {
    addNameInternal(_name, msg.sender);
    bytes32 hash = keccak256(abi.encodePacked(msg.sender));
    require (sig.length == 65, 'bad signature length');
    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    uint idx = 32;
    bytes32 r;
    assembly
    {
      r := mload(add(sig, idx))
    }

    idx += 32;
    bytes32 s;
    assembly
    {
      s := mload(add(sig, idx))
    }

    idx += 1;
    uint8 v;
    assembly
    {
      v := mload(add(sig, idx))
    }
    if (v <= 1) v += 27;
    require(v==27 || v==28,'bad sig v');

    address plasma_address = ecrecover(hash, v, r, s);
    plasma2ethereum[plasma_address] = msg.sender;
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }
}
