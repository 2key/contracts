pragma solidity ^0.4.24;

import "./Upgradeable.sol";
import './Call.sol';

contract TwoKeyRegistry is Upgradeable {  //TODO Nikola why is this not inheriting from MaintainerPattern?

    using Call for *;

    /// mapping user's address to user's name
    mapping(address => string) public address2username;
    /// mapping user's name to user's address
    mapping(bytes32 => address) public username2currentAddress;
    /// mapping username to array of addresses he is using/used
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
    mapping(address => address) plasma2ethereum;
    mapping(address => address) ethereum2plasma;

    mapping(address => bytes) public notes;

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
    mapping(address => bool) public isMaintainer;

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
     * @param _maintainers is the address of initial maintainer
     */
    function setInitialParams(address _twoKeyEventSource, address _twoKeyAdmin, address [] _maintainers) external {
        require(twoKeyEventSource == address(0));
        require(twoKeyAdminContractAddress == address(0));
        twoKeyEventSource = _twoKeyEventSource;
        twoKeyAdminContractAddress = _twoKeyAdmin;

        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /// @notice Function to check if maintainer exists
    /// @param _maintainer is the address of maintainer we're checking occurence
    /// @return true if exists otherwise false
    function checkIfTwoKeyMaintainerExists(address _maintainer) public view returns (bool) {
        return isMaintainer[_maintainer];
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
        bytes32 name = stringToBytes32(_name);
        // check if name is taken
        if (username2currentAddress[name] != 0) {
            revert();
        }
        // remove previous name
        bytes memory last_name = bytes(address2username[_sender]);
        if (last_name.length != 0) {
            username2currentAddress[name] = 0;
        }
        address2username[_sender] = _name;
        username2currentAddress[name] = _sender;
        // Add history of changes
        username2AddressHistory[name].push(_sender);
        emit UserNameChanged(_sender, _name);
    }

    /**
     * @notice Function to concat this 2 functions at once
     */
    function addNameAndSetWalletName(
        string _name,
        address _sender,
        string _fullName,
        string _email,
        string _username_walletName,
        bytes _signatureName,
        bytes _signatureWalletName
    ) public onlyTwoKeyMaintainer  {
        addName(_name, _sender, _fullName, _email, _signatureName);
        setWalletName(_name, _sender, _username_walletName, _signatureWalletName);
    }

    /// @notice Function where only admin can add a name - address pair
    /// @param _name is name of user
    /// @param _sender is address of user
    function addName(string _name, address _sender, string _fullName, string _email, bytes signature) public {
        require(isMaintainer[msg.sender] == true || msg.sender == address(this));
//        require(utfStringLength(_name) >= 3 && utfStringLength(_name) <=25);

        string memory concatenatedValues = strConcat(_name,_fullName,_email);
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        require(message_signer == _sender);
        addressToUserData[_sender] = UserData({
            username: _name,
            fullName: _fullName,
            email: _email
        });
        addNameInternal(_name, _sender);
    }

    /// @notice Add signed name
    /// @param _name is the name
    /// @param external_sig is the external signature
    function addNameSigned(string _name, bytes external_sig) public {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(_name))));
        address eth_address = Call.recoverHash(hash,external_sig,0);
        require (msg.sender == eth_address || isMaintainer[msg.sender] == true, "only maintainer or user can change name");
        addNameInternal(_name, eth_address);
    }

    function setNoteInternal(bytes note, address me) private {
        // note is a message you can store with sig. For example it could be the secret you used encrypted by you
        notes[me] = note;
    }

    function setNoteByUser(bytes note) public {
        // note is a message you can store with sig. For example it could be the secret you used encrypted by you
        setNoteInternal(note, msg.sender);
    }

//    /// @notice Function where user can add name to his address
//    /// @param _name is name of user
//    function addNameByUser(string _name) external {
//        require(utfStringLength(_name) >= 3 && utfStringLength(_name) <=25);
//        addNameInternal(_name, msg.sender);
//    }

    /**
     * @notice function to add single maintainer
     * @param _maintainers is the address of maintainer
     * @dev only the person who deploys the contract can call this
     */
    function addTwoKeyMaintainers(address [] _maintainers) public onlyAdmin {
        require(_maintainers.length > 0);
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice function to remove single maintainer
     * @param _maintainers is the address of maintainer
     * @dev only the person who deploys the contract can call this
     */
    function removeTwoKeyMaintainer(address [] _maintainers) public onlyAdmin {
        require(_maintainers.length > 0);
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }

    /// @notice Function where TwoKeyMaintainer can add walletname to address
    /// @param username is the username of the user we want to update map for
    /// @param _address is the address of the user we want to update map for
    /// @param _username_walletName is the concatenated username + '_' + walletName, since sending from trusted provider no need to validate
    function setWalletName(string memory username, address _address, string memory _username_walletName, bytes signature) public {
        require(isMaintainer[msg.sender] == true || msg.sender == address(this));
        require(_address != address(0));
        bytes32 usernameHex = stringToBytes32(username);
        require(username2currentAddress[usernameHex] == _address); // validating that username exists

        string memory concatenatedValues = strConcat(username,_username_walletName,"");
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        require(message_signer == _address);
        bytes32 walletTag = stringToBytes32(_username_walletName);
        address2walletTag[_address] = walletTag;
        walletTag2address[walletTag] = _address;
    }

    function addPlasma2EthereumInternal(bytes sig, address eth_address) private {
        // add an entry connecting msg.sender to the ethereum address that was used to sign sig.
        // see setup_demo.js on how to generate sig
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum address")),keccak256(abi.encodePacked(eth_address))));
        address plasma_address = Call.recoverHash(hash,sig,0);
        require(plasma2ethereum[plasma_address] == address(0) || plasma2ethereum[plasma_address] == eth_address, "cant change eth=>plasma");
        plasma2ethereum[plasma_address] = eth_address;
        ethereum2plasma[eth_address] = plasma_address;
    }

    function addPlasma2EthereumByUser(bytes sig) public {
        addPlasma2EthereumInternal(sig, msg.sender);
    }

    function setPlasma2EthereumAndNoteSigned(bytes sig, bytes note, bytes external_sig) public {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum-plasma")),
            keccak256(abi.encodePacked(sig,note))));
        address eth_address = Call.recoverHash(hash,external_sig,0);
        require (msg.sender == eth_address || isMaintainer[msg.sender], "only maintainer or user can change ethereum-plasma");
        addPlasma2EthereumInternal(sig, eth_address);
        setNoteInternal(note, eth_address);
    }

    /// View function - doesn't cost any gas to be executed
    /// @notice Function to fetch address of the user that corresponds to given name
    /// @param _name is name of user
    /// @return address of the user as type address
    function getUserName2UserAddress(string _name) external view returns (address) {
        bytes32 name = stringToBytes32(_name);
        return username2currentAddress[name];
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
        bytes32 nameHex = stringToBytes32(name);
        return username2AddressHistory[nameHex];
    }

    /**
     */
    function deleteUserByAddress(address _ethereumAddress) public onlyTwoKeyMaintainer {
        string memory userName = address2username[_ethereumAddress];
        address2username[_ethereumAddress] = "";

        bytes32 userNameHex = stringToBytes32(userName);
        username2currentAddress[userNameHex] = address(0);

        bytes32 walletTag = address2walletTag[_ethereumAddress];
        address2walletTag[_ethereumAddress] = bytes32(0);
        walletTag2address[walletTag] = address(0);

        address plasma = ethereum2plasma[_ethereumAddress];
        ethereum2plasma[_ethereumAddress] = address(0);
        plasma2ethereum[plasma] = address(0);

        UserData memory userdata = addressToUserData[_ethereumAddress];
        userdata.username = "";
        userdata.fullName = "";
        userdata.email = "";
        addressToUserData[_ethereumAddress] = userdata;

        notes[_ethereumAddress] = "";
    }


//    /// @notice Function to fetch actual length of string
//    /// @param str is the string we'd like to get length of
//    /// @return length of the string
//    function utfStringLength(string str) internal pure returns (uint length) {
//        uint i=0;
//        bytes memory string_rep = bytes(str);
//
//        while (i<string_rep.length)
//        {
//            if (string_rep[i]>>7==0)
//                i+=1;
//            else if (string_rep[i]>>5==0x6)
//                i+=2;
//            else if (string_rep[i]>>4==0xE)
//                i+=3;
//            else if (string_rep[i]>>3==0x1E)
//                i+=4;
//            else
//            //For safety
//                i+=1;
//            length++;
//        }
//    }

    /**
     * @notice Reading from mapping ethereum 2 plasma
     * @param plasma is the plasma address we're searching eth address for
     * @return ethereum address if exist otherwise 0x0 (address(0))
     */
    function getPlasmaToEthereum(address plasma) public view returns (address) {
        return plasma2ethereum[plasma];
    }

    /**
     * @notice Reading from mapping plasma 2 ethereum
     * @param ethereum is the ethereum address we're searching plasma address for
     * @return plasma address if exist otherwise 0x0 (address(0))
     */
    function getEthereumToPlasma(address ethereum) public view returns (address) {
        return ethereum2plasma[ethereum];
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


    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice Function to concat at most 5 strings
     * @dev If you want to handle concatenation of less than 5, then pass first their values and for the left pass empty strings
     * @return string concatenated
     */
    function strConcat(string _a, string _b, string _c) public pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        return string(babcde);
    }

    function getUserData(address _user) external view returns (bytes32,bytes32,bytes32) {
        UserData memory data = addressToUserData[_user];
        bytes32 username = stringToBytes32(data.username);
        bytes32 fullName = stringToBytes32(data.fullName);
        bytes32 email = stringToBytes32(data.email);
        return (username, fullName, email);
    }

}
