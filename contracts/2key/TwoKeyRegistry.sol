pragma solidity ^0.4.24;

import "./Upgradeable.sol";

contract TwoKeyRegistry is Upgradeable {

    /// mapping user's address to user's name
    mapping(address => string) public address2username;
    /// mapping user's name to user's address
    mapping(bytes32 => address) public username2currentAddress;
    // mapping username to array of addresses he is using/used
    mapping(bytes32 => address[]) public username2AddressHistory;
    /*
        mapping address to wallet tag
        wallet tag = username + '_' + walletname
    */
    mapping(address => bytes32) public address2walletTag;

    // reverse mapping from walletTag to address
    mapping(bytes32 => address) public walletTag2address;

    // plasma address => ethereum address
    // note that more than one plasma address can point to the same ethereum address so it is not critical to use the same plasma address all the time for the same user
    // in some cases the plasma address will be the same as the ethereum address and in that case it is not necessary to have an entry
    // the way to know if an address is a plasma address is to look it up in this mapping
    mapping(address => address) public plasma2ethereum;

    struct UserData {
        string username;
        string fullName;
        string email;
    }

    mapping(address => UserData) addressToUserData;

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

    /// Address of 2key event source contract which will have permission to write on this contract
    /// (Address is enough, there is no need to spend sufficient gas and instantiate whole contract)
    address public twoKeyEventSource;

    /// Address for contract maintainer
    /// Should be the array of addresses - will have permission on some of the mappings to update
    address[] maintainers;

    address twoKeyAdminContractAddress;

    /// @notice Event is emitted when a user's name is changed
    event UserNameChanged(address owner, string name);


    /// Modifier which will allow only 2key event source to issue calls on selected methods
    modifier onlyTwoKeyEventSource {
        require(msg.sender == twoKeyEventSource);
        _;
    }

    /// Modifier which will allow only 2keyAdmin or maintainer to invoke function calls
    modifier onlyTwoKeyAuthorized {
        require(msg.sender == twoKeyAdminContractAddress || checkIfTwoKeyMaintainerExists(msg.sender));
        _;
    }


    /// Modifier which will allow only 2keyMaintainer to invoke function calls
    modifier onlyTwoKeyMaintainer {
        require(checkIfTwoKeyMaintainerExists(msg.sender));
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == twoKeyAdminContractAddress);
        _;
    }

    /**
     * @notice Function which can be called only once
     * @param _twoKeyEventSource is the address of twoKeyEventSource contract
     * @param _twoKeyAdmin is the address of twoKeyAdmin contract
     * @param _maintainer is the address of initial maintainer
     */
    function setInitialParams(address _twoKeyEventSource, address _twoKeyAdmin, address _maintainer) external {
        require(twoKeyEventSource == address(0));
        require(twoKeyAdminContractAddress == address(0));
        twoKeyEventSource = _twoKeyEventSource;
        twoKeyAdminContractAddress = _twoKeyAdmin;
        maintainers.push(_maintainer);
    }

    /// @notice Function to check if maintainer exists
    /// @param _maintainer is the address of maintainer we're checking occurence
    /// @return true if exists otherwise false
    function checkIfTwoKeyMaintainerExists(address _maintainer) public view returns (bool) {
        for(uint i=0; i<maintainers.length; i++) {
              if(_maintainer == maintainers[i]) {
                  return true;
              }
        }
        return false;
    }

    function getMaintainers() public view returns (address[]){
        return maintainers;
    }


    /// Only TwoKeyEventSource contract can issue this calls
    /// @notice Function to add new campaign contract where user is contractor
    /// @dev We're requiring the contract address different address 0 because it needs to be deployed
    /// @param _userAddress is address of contractor
    /// @param _contractAddress is address of deployed campaign contract
    function addWhereContractor(address _userAddress, address _contractAddress) external onlyTwoKeyEventSource {
        require(_contractAddress != address(0));
        userToCampaignsWhereContractor[_userAddress].push(_contractAddress);
    }

    /// Only TwoKeyEventSource contract can issue this calls
    /// @notice Function to add new campaign contract where user is moderator
    /// @dev We're requiring the contract address different address 0 because it needs to be deployed
    /// @param _userAddress is address of moderator
    /// @param _contractAddress is address of deployed campaign contract
    function addWhereModerator(address _userAddress, address _contractAddress) external onlyTwoKeyEventSource {
        require(_contractAddress != address(0));
        userToCampaignsWhereModerator[_userAddress].push(_contractAddress);
    }

    /// Only TwoKeyEventSource contract can issue this calls
    /// @notice Function to add new campaign contract where user is refferer
    /// @dev We're requiring the contract address different address 0 because it needs to be deployed
    /// @param _userAddress is address of refferer
    /// @param _contractAddress is address of deployed campaign contract
    function addWhereReferrer(address _userAddress, address _contractAddress) external onlyTwoKeyEventSource {
        require(_contractAddress != address(0));
        userToCampaignsWhereReferrer[_userAddress].push(_contractAddress);
    }

    /// Only TwoKeyEventSource contract can issue this calls
    /// @notice Function to add new campaign contract where user is converter
    /// @dev We're requiring the contract address different address 0 because it needs to be deployed
    /// @param _userAddress is address of converter
    /// @param _contractAddress is address of deployed campaign contract
    function addWhereConverter(address _userAddress, address _contractAddress) external onlyTwoKeyEventSource {
        require(_contractAddress != address(0));
        userToCampaignsWhereConverter[_userAddress].push(_contractAddress);
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch all campaign contracts where user is contractor
    /// @param _userAddress is address of user
    /// @return array of addresses (campaign contracts)
    function getContractsWhereUserIsContractor(address _userAddress) external view returns (address[]) {
        require(_userAddress != address(0));
        return userToCampaignsWhereContractor[_userAddress];
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch all campaign contracts where user is moderator
    /// @param _userAddress is address of user
    /// @return array of addresses (campaign contracts)
    function getContractsWhereUserIsModerator(address _userAddress) external view returns (address[]) {
        require(_userAddress != address(0));
        return userToCampaignsWhereModerator[_userAddress];
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch all campaign contracts where user is refferer
    /// @param _userAddress is address of user
    /// @return array of addresses (campaign contracts)
    function getContractsWhereUserIsReferrer(address _userAddress) external view returns (address[]) {
        require(_userAddress != address(0));
        return userToCampaignsWhereReferrer[_userAddress];
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch all campaign contracts where user is converter
    /// @param _userAddress is address of user
    /// @return array of addresses (campaign contracts)
    function getContractsWhereUserIsConverter(address _userAddress) external view returns (address[]) {
        require(_userAddress != address(0));
        return userToCampaignsWhereConverter[_userAddress];
    }


    /// @notice Function where new name/address pair is added or an old address is updated with new name
    /// @dev private function
    /// @param _name is name of user
    /// @param _sender is address of user
    function addNameInternal(string _name, address _sender) private {
        // check if name is taken
        if (username2currentAddress[keccak256(abi.encodePacked(_name))] != 0) {
            revert();
        }
        // remove previous name
        bytes memory last_name = bytes(address2username[_sender]);
        if (last_name.length != 0) {
            username2currentAddress[keccak256(abi.encodePacked(address2username[_sender]))] = 0;
        }
        address2username[_sender] = _name;
        username2currentAddress[keccak256(abi.encodePacked(_name))] = _sender;
        // Add history of changes
        username2AddressHistory[keccak256(abi.encodePacked(_name))].push(_sender);
        emit UserNameChanged(_sender, _name);
    }

    /// @notice Function where only admin can add a name - address pair
    /// @param _name is name of user
    /// @param _sender is address of user
    //onlyTwoKeyMaintainer
    function addName(string _name, address _sender, string _fullName, string _email) public onlyTwoKeyMaintainer {
        require(utfStringLength(_name) >= 3 && utfStringLength(_name) <=25);
        addressToUserData[_sender] = UserData({
            username: _name,
            fullName: _fullName,
            email: _email
            });
        addNameInternal(_name, _sender);
    }

    function getUserData(address _user) external view returns (bytes32,bytes32,bytes32) {
        UserData memory data = addressToUserData[_user];
        bytes32 username = stringToBytes32(data.username);
        bytes32 fullName = stringToBytes32(data.fullName);
        bytes32 email = stringToBytes32(data.email);
        return (username, fullName, email);
    }

    /// @notice Function where user can add name to his address
    /// @param _name is name of user
    function addNameByUser(string _name) external {
        require(utfStringLength(_name) >= 3 && utfStringLength(_name) <=25);
        addNameInternal(_name, msg.sender);
    }

    /// @notice Function where TwoKeyMaintainer can add walletname to address
    /// @param username is the username of the user we want to update map for
    /// @param _address is the address of the user we want to update map for
    /// @param _username_walletName is the concatenated username + '_' + walletName, since sending from trusted provider no need to validate
    function setWalletName(string memory username, address _address, string memory _username_walletName) public onlyTwoKeyMaintainer {
        require(_address != address(0));
        require(username2currentAddress[keccak256(abi.encodePacked(username))] == _address); // validating that username exists

        address2walletTag[_address] = keccak256(abi.encodePacked(_username_walletName));
        walletTag2address[keccak256(abi.encodePacked(_username_walletName))] = _address;
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch address of the user that corresponds to given name
    /// @param _name is name of user
    /// @return address of the user as type address
    function getUserName2UserAddress(string _name) external view returns (address) {
        return username2currentAddress[keccak256(abi.encodePacked(_name))];
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch name that corresponds to the address
    /// @param _sender is address of user
    /// @return name of the user as type string
    function getUserAddress2UserName(address _sender) external view returns (string) {
        return address2username[_sender];
    }


    /// Get history of changed addresses
    /// @return array of addresses sorted
    function getHistoryOfChangedAddresses() external view returns (address[]) {
        string memory name = address2username[msg.sender];
        return username2AddressHistory[keccak256(abi.encodePacked(name))];
    }

    /// @notice Function to fetch actual length of string
    /// @param str is the string we'd like to get length of
    /// @return length of the string
    function utfStringLength(string str) internal pure returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==0x6)
                i+=2;
            else if (string_rep[i]>>4==0xE)
                i+=3;
            else if (string_rep[i]>>3==0x1E)
                i+=4;
            else
            //For safety
                i+=1;
            length++;
        }
    }

    /**
     * @notice Function to add plasma address to ethereum
     * @param sig is the signature
     */
    function addPlasma2Ethereum(bytes sig) public {
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
        require(plasma2ethereum[plasma_address] == address(0) || plasma2ethereum[plasma_address] == msg.sender, "cant change plasma=>eth");
        plasma2ethereum[plasma_address] = msg.sender;
    }

    /**
     * @notice Function to check if the user exists
     * @param _userAddress is the address of the user
     * @return true if exists otherwise false
     */
    function checkIfUserExists(address _userAddress) external view returns (bool) {
        bytes memory tempEmptyStringTest = bytes(address2username[_userAddress]);
        if (tempEmptyStringTest.length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function addTwoKeyMaintainer(address _maintainer) public onlyAdmin {
        require(_maintainer != address(0));
        maintainers.push(_maintainer);
    }

}
