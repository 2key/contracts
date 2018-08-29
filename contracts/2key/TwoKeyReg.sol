pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract TwoKeyReg is Ownable {

  /// Address of 2key event source contract which will have permission to write on this contract
  /// (Address is enough, there is no need to spend sufficient gas and instantiate whole contract)
  address twoKeyEventSource;

  /// Modifier which will allow only 2key event source to issue calls on selected methods
  modifier onlyTwoKeyEventSource {
    require(msg.sender == twoKeyEventSource);
    _;
  }

  /// Only TwoKeyReg owner can call this method (modifier) since TwoKeyReg is Ownable
  /// @notice Method which will allow us to add allowed 2key event source contract to write here
  /// @dev Only owner can call this method (?)
  /// @param _twoKeyEventSource is address of already deployed 2key Event source contract
  function addTwoKeyEventSource(address _twoKeyEventSource) onlyOwner {
    require(twoKeyEventSource == address(0));
    require(_twoKeyEventSource != address(0));

    twoKeyEventSource = _twoKeyEventSource;
  }

  /// @notice Method to change the allowed TwoKeyEventSource contract address
  /// @param _twoKeyEventSource new TwoKeyEventSource contract address
  function changeTwoKeyEventSource(address _twoKeyEventSource) onlyOwner {
    require(_twoKeyEventSource != address(0));

    twoKeyEventSource = _twoKeyEventSource;
  }
  /*
    Those mappings are for the fetchin informations about in what contracts user participates in which role
  */

  /// mapping users address to addresses of campaigns where he is contractor
  mapping(address => address[]) public userToCampaignsWhereContractor;

  /// mapping users address to addresses of campaigns where he is moderator
  mapping(address => address[]) public userToCampaignsWhereModerator;

  /// mapping users address to addresses of campaigns where he is refferer
  mapping(address => address[]) public userToCampaignsWhereRefferer;

  /// mapping users address to addresses of campaigns where he is converter
  mapping(address => address[]) public userToCampaignsWhereConverter;



  mapping(address => string) public owner2name;
  mapping(bytes32 => address) public name2owner;

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

  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }

}
