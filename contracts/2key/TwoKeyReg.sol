pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './TwoKeyEconomy.sol';

contract TwoKeyReg is Ownable {
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;

  event UserNameChanged(address owner, string name);

  TwoKeyEconomy public economy;
  uint signup_amount;  // the first time a user adds a name she will receive 2key tokens in this amount
  function setEconomy(address _economy, uint _signup_amount) onlyOwner public {
    economy = TwoKeyEconomy(_economy);
    signup_amount = _signup_amount;
  }

    //  // Initialize all the constants
//  constructor(address _economy, uint _signup_amount) public {
//    economy = TwoKeyEconomy(_economy);
//    signup_amount = _signup_amount;
//  }

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

    if (last_name.length == 0  && economy != address(0)) {
      // first time
      uint supply = economy.balanceOf(this);
      if (supply < signup_amount) {
        signup_amount = supply;
      }
      economy.transfer(_sender, signup_amount);
//      require(address(economy).call(bytes4(keccak256("transfer(address,uint256)")),_sender,signup_amount));
    }
  }

  function addName(string _name, address _sender) onlyOwner public {
    addNameInternal(_name, _sender);
  }

  function addNameByUser(string _name) public {
    addNameInternal(_name, msg.sender);
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }

}
