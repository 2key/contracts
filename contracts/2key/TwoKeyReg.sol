pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./RBACWithAdmin.sol";
import "./TwoKeyAdmin.sol";

contract TwoKeyReg is Ownable, RBACWithAdmin {

  /// Address of 2key event source contract which will have permission to write on this contract
  /// (Address is enough, there is no need to spend sufficient gas and instantiate whole contract)
  address twoKeyEventSource;

  /// Address for contract maintainer
  address maintainer;

  TwoKeyAdmin twoKeyAdminContract;

  /// Modifier which will allow only 2key event source to issue calls on selected methods
  modifier onlyTwoKeyEventSource {
    require(msg.sender == twoKeyEventSource);
    _;
  }
  /// TODO: (Amit) Put this modifier on methods where required
  /// Modifier which will allow only 2keyAdmin or maintener to invoke function calls
  modifier onlyTwoKeyAuthorized {
    require(msg.sender == address(twoKeyAdminContract) || msg.sender == maintainer);
    _;
  }

  constructor (address _twoKeyEventSource, address _twoKeyAdmin) RBACWithAdmin(_twoKeyAdmin)  public {
    require(_twoKeyEventSource != address(0));
    require(_twoKeyAdmin != address(0));
    twoKeyEventSource = _twoKeyEventSource;
    twoKeyAdminContract = TwoKeyAdmin( _twoKeyAdmin);   
  }

 // function addTwoKeyEventSource(address _twoKeyEventSource) public onlyOwner {
 //   require(twoKeyEventSource == address(0));
 //   require(_twoKeyEventSource != address(0));

 //   twoKeyEventSource = _twoKeyEventSource;
 // }

  /// @notice Method to change the allowed TwoKeyEventSource contract address
  /// @param _twoKeyEventSource new TwoKeyEventSource contract address
  function changeTwoKeyEventSource(address _twoKeyEventSource) public onlyOwner {
    require(_twoKeyEventSource != address(0));

    twoKeyEventSource = _twoKeyEventSource;
  }
  
  /*
    Those mappings are for the fetching data about in what contracts user participates in which role
  */
  /// mapping users address to addresses of campaigns where he is contractor
  mapping(address => address[]) public userToCampaignsWhereContractor;

  /// mapping users address to addresses of campaigns where he is moderator
  mapping(address => address[]) public userToCampaignsWhereModerator;

  /// mapping users address to addresses of campaigns where he is refferer
  mapping(address => address[]) public userToCampaignsWhereReferrer;

  /// mapping users address to addresses of campaigns where he is converter
  mapping(address => address[]) public userToCampaignsWhereConverter;

  /// Only TwoKeyEventSource contract can issue this calls
  /// @notice Function to add new campaign contract where user is contractor
  /// @dev We're requiring the contract address different address 0 because it needs to be deployed
  /// @param _userAddress is address of contractor
  /// @param _contractAddress is address of deployed campaign contract
  /// commented modifier onlyTwoKeyEventSource
  function addWhereContractor(address _userAddress, address _contractAddress) public{
   // require(_contractAddress != address(0));
    userToCampaignsWhereContractor[_userAddress].push(_contractAddress);
  }
  /// Only TwoKeyEventSource contract can issue this calls
  /// @notice Function to add new campaign contract where user is moderator
  /// @dev We're requiring the contract address different address 0 because it needs to be deployed
  /// @param _userAddress is address of moderator
  /// @param _contractAddress is address of deployed campaign contract
  function addWhereModerator(address _userAddress, address _contractAddress) public onlyTwoKeyEventSource {
    require(_contractAddress != address(0));
    userToCampaignsWhereModerator[_userAddress].push(_contractAddress);
  }

  /// Only TwoKeyEventSource contract can issue this calls
  /// @notice Function to add new campaign contract where user is refferer
  /// @dev We're requiring the contract address different address 0 because it needs to be deployed
  /// @param _userAddress is address of refferer
  /// @param _contractAddress is address of deployed campaign contract
  function addWhereReferrer(address _userAddress, address _contractAddress) public onlyTwoKeyEventSource {
    require(_contractAddress != address(0));
    userToCampaignsWhereReferrer[_userAddress].push(_contractAddress);
  }

  /// Only TwoKeyEventSource contract can issue this calls
  /// @notice Function to add new campaign contract where user is converter
  /// @dev We're requiring the contract address different address 0 because it needs to be deployed
  /// @param _userAddress is address of converter
  /// @param _contractAddress is address of deployed campaign contract
  function addWhereConverter(address _userAddress, address _contractAddress) public onlyTwoKeyEventSource {
    require(_contractAddress != address(0));
    userToCampaignsWhereConverter[_userAddress].push(_contractAddress);
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch all campaign contracts where user is contractor
  /// @param _userAddress is address of user
  /// @return array of addresses (campaign contracts)
  function getContractsWhereUserIsContractor(address _userAddress) public view returns (address[]) {
      require(_userAddress != address(0));
      return userToCampaignsWhereContractor[_userAddress];
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch all campaign contracts where user is moderator
  /// @param _userAddress is address of user
  /// @return array of addresses (campaign contracts)
  function getContractsWhereUserIsModerator(address _userAddress) public view returns (address[]) {
      require(_userAddress != address(0));
      return userToCampaignsWhereModerator[_userAddress];
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch all campaign contracts where user is refferer
  /// @param _userAddress is address of user
  /// @return array of addresses (campaign contracts)
  function getContractsWhereUserIsReferrer(address _userAddress) public view returns (address[]) {
      require(_userAddress != address(0));
      return userToCampaignsWhereReferrer[_userAddress];
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch all campaign contracts where user is converter
  /// @param _userAddress is address of user
  /// @return array of addresses (campaign contracts)
  function getContractsWhereUserIsConverter(address _userAddress) public view returns (address[]) {
      require(_userAddress != address(0));
      return userToCampaignsWhereConverter[_userAddress];
  }

  /// View function to return address of current active twoKeyEventSource contract
  /// @notice Function to fetch twoKeyEventSource contract address 
  function getTwoKeyEventSourceAddress() public view returns (address) {
    return twoKeyEventSource;
  }

  /// mapping user's address to user's name 
  mapping(address => string) public owner2name;
  /// mapping user's name to user's address 
  mapping(bytes32 => address) public name2owner;

  /// @notice Event is emitted when a user's name is changed
  event UserNameChanged(address owner, string name);

  /// @notice Function where new name/address pair is added or an old address is updated with new name
  /// @dev private function 
  /// @param _name is name of user
  /// @param _sender is address of user
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

  /// @notice Function where only admin can add a name - address pair 
  /// @param _name is name of user
  /// @param _sender is address of user
  function addName(string _name, address _sender) onlyAdmin public {
    addNameInternal(_name, _sender);
  }

  /// @notice Function where user can add name to his address 
  /// @param _name is name of user
  function addNameByUser(string _name) public {
    addNameInternal(_name, msg.sender);
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch address of the user that corresponds to given name
  /// @param _name is name of user
  /// @return address of the user as type address
  function getName2Owner(string _name) public view returns (address) {
    return name2owner[keccak256(abi.encodePacked(_name))];
  }

  /// View function - doesn't cost any gas to be executed
  /// @notice Function to fetch name that corresponds to the address
  /// @param _sender is address of user
  /// @return name of the user as type string
  function getOwner2Name(address _sender) public view returns (string) {
    return owner2name[_sender];
  }

}
