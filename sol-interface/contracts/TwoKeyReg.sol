pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use
//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TwoKeyReg
//is Ownable
{
  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;

  event UserNameChanged(address owner, string name);
  function addName(string _name) public {
    address _owner = msg.sender;
    // check if name is taken
    if (name2owner[keccak256(abi.encodePacked(_name))] != 0) {
      revert();
    }
    // remove previous name
    bytes memory last_name = bytes(owner2name[_owner]);
    if (last_name.length != 0) {
      name2owner[keccak256(abi.encodePacked(owner2name[_owner]))] = 0;
    }
    owner2name[_owner] = _name;
    name2owner[keccak256(abi.encodePacked(_name))] = _owner;
    emit UserNameChanged(_owner, _name);
  }

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _owner) public view returns (string) {
    return owner2name[_owner];
  }

  // Moved to TwoKeyEventSource
//  event Created(address indexed owner, address c);
//  function createdContract(address _owner) public {
//    address c = msg.sender;
//    // TODO Yoram: check if we can get the code of c and check if the has exists in a list allowed codes
//    // TODO Yoram: only the owner of TwoKeyReg is allowed to edit the list of allowed codes
//    emit Created(_owner, c);
//  }

  // Its better if dApp handles created contract by itself
//  event Verified(address indexed owner, address c);
//  function verifiedContract(address owner, address c) onlyOwner public {
//    emit Verified(owner, c);
//  }

  // Moved to TwoKeyEventSource
//  event Joined(address indexed to, address c);
//  function joinedContract(address to) public {
//    address c = msg.sender;
//    emit Joined(to, c);
//  }
}
