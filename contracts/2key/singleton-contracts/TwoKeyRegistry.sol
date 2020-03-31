pragma solidity ^0.4.24;

import "../libraries/Call.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../libraries/Utils.sol";
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyRegistryStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";


contract TwoKeyRegistry is Upgradeable, Utils, ITwoKeySingletonUtils {

    using Call for *;

    bool initialized;

    string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";

    ITwoKeyRegistryStorage public PROXY_STORAGE_CONTRACT;


    event UserNameChanged(
        address owner,
        string name
    );


    /**
     * @notice          Function which can be called only once
     *                  used as a constructor
     *
     * @param           _twoKeySingletonesRegistry is the address of TwoKeySingletonsRegistry contract
     * @param           _proxyStorage is the address of the proxy contract used as a storage
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyRegistryStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice          Function which is called either during the registration or when user
     *                  decides to change his username
     *
     * @param           _username is the new username user want's to set. Must be unique.
     * @param           _userAddress is the address of the user who is this action being
     *                  performed for.
     *
     */
    function addOrChangeUsernameInternal(
        string _username,
        address _userAddress
    )
    internal
    {
        // Generate the name in the bytes
        bytes32 usernameBytes32 = stringToBytes32(_username);

        bytes32 keyHashUserNameToAddress = keccak256("username2currentAddress", usernameBytes32);
        bytes32 keyHashAddressToUserName = keccak256("address2username", _userAddress);

        // check if name is taken
        if (PROXY_STORAGE_CONTRACT.getAddress(keyHashUserNameToAddress) != address(0)) {
            revert();
        }

        // Set mapping address => username
        PROXY_STORAGE_CONTRACT.setString(keyHashAddressToUserName, _username);

        // Set mapping username => address
        PROXY_STORAGE_CONTRACT.setAddress(keyHashUserNameToAddress, _userAddress);

        // Emit event that username is added or changed
        emit UserNameChanged(_userAddress, _username);
    }


    /**
     * @notice          Function where maintainer can register user
     *
     * @param           _username is the username of the user
     * @param           _userAddress is the address of the user
     * @param           _fullName is the full name of the user
     * @param           _email is the email address of the user
     * @param           signature is the message user signed with his wallet
     */
    function addName(
        string _username,
        address _userAddress,
        string _fullName,
        string _email,
        bytes signature
    )
    internal
    {
        // Concat the arguments
        string memory concatenatedValues = strConcat(_username, _fullName, _email);
        // Generate hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(concatenatedValues))));

        // Take the signer of the message
        address message_signer = Call.recoverHash(hash, signature, 0);

        // Assert that the message signer is the _sender in the arguments
        require(message_signer == _userAddress);

        // Generate the keys for the storage contract
        bytes32 keyHashUsername = keccak256("addressToUserData", "username", _userAddress);
        bytes32 keyHashFullName = keccak256("addressToUserData", "fullName", _userAddress);
        bytes32 keyHashEmail = keccak256("addressToUserData", "email", _userAddress);

        // Set the values
        PROXY_STORAGE_CONTRACT.setString(keyHashUsername, _username);
        PROXY_STORAGE_CONTRACT.setString(keyHashFullName, _fullName);
        PROXY_STORAGE_CONTRACT.setString(keyHashEmail, _email);


        addOrChangeUsernameInternal(_username, _userAddress);
    }

    /**
     * @notice          Function where maintainer can add walletName to address
     *
     * @param           username is the username of the user we want to update wallet name for
     * @param           _address is the address of the user we want to update wallet name for
     * @param           _username_walletName is the concatenated username + '_' + walletName,
     *                  since sending from trusted provider no need to validate
     * @param           signature is the sig where user ad
     */
    function setWalletName(
        string memory username,
        address _address,
        string memory _username_walletName,
        bytes signature
    )
    internal
    {
        bytes32 usernameHex = stringToBytes32(username);
        address usersAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256("username2currentAddress", usernameHex));

        require(usersAddress == _address); // validating that username exists

        string memory concatenatedValues = strConcat(username,_username_walletName,"");

        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        require(message_signer == _address);

        bytes32 walletTag = stringToBytes32(_username_walletName);
        bytes32 keyHashAddress2WalletTag = keccak256("address2walletTag", _address);
        PROXY_STORAGE_CONTRACT.setBytes32(keyHashAddress2WalletTag, walletTag);

        bytes32 keyHashWalletTag2Address = keccak256("walletTag2address", walletTag);
        PROXY_STORAGE_CONTRACT.setAddress(keyHashWalletTag2Address, _address);
    }


    /**
     * @notice          Internal function for setting note
     *
     * @param           note is the note user wants to set
     * @param           userAddress is the address of the user
     */
    function setNoteInternal(
        bytes note,
        address userAddress
    )
    internal
    {
        bytes32 keyHashNotes = keccak256("notes", userAddress);
        PROXY_STORAGE_CONTRACT.setBytes(keyHashNotes, note);
    }


    /**
     * @notice          Function to map plasma and ethereum addresses for the user
     *
     * @param           signature is the message user signed so we can take his plasma_address
     * @param           ethereumAddress is the ethereum address of the user who signed the message
     *
     */
    function addPlasma2EthereumInternal(
        bytes signature,
        address ethereumAddress
    )
    internal
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum address")),keccak256(abi.encodePacked(ethereumAddress))));
        address plasmaAddress = Call.recoverHash(hash,signature,0);

        bytes32 keyHashPlasmaToEthereum = keccak256("plasma2ethereum", plasmaAddress);
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", ethereumAddress);


        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum) == address(0) || PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum) == ethereumAddress, "cant change eth=>plasma");
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma) == address(0) || PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma) == plasmaAddress);

        PROXY_STORAGE_CONTRACT.setAddress(keyHashPlasmaToEthereum, ethereumAddress);
        PROXY_STORAGE_CONTRACT.setAddress(keyHashEthereumToPlasma, plasmaAddress);
    }

    /**
     * @notice          Function concatenating calls for both addName and setWalletName
     *
     * @param           _username is the username user want's to set
     * @param           _userAddress is the address of the user
     * @param           _fullName is users full name
     * @param           _email is the email address of the user
     * @param           _username_walletName is the concatenated username and wallet name
     * @param           _signatureUsername is the signature for name
     * @param           _signatureWalletName is the signature for wallet name
     *
     */
    function addNameAndSetWalletName(
        string _username,
        address _userAddress,
        string _fullName,
        string _email,
        string _username_walletName,
        bytes _signatureUsername,
        bytes _signatureWalletName
    )
    public
    onlyMaintainer
    {
        addName(_username, _userAddress, _fullName, _email, _signatureUsername);
        setWalletName(_username, _userAddress, _username_walletName, _signatureWalletName);
    }


    /**
     * @notice          Function where username can be changed
     *
     * @param           newUsername is the new username user wants to add
     * @param           userAddress is the ethereum address of the user
     * @param           signature is the signature of the user
     */
    function changeUsername(
        string newUsername,
        address userAddress,
        bytes signature
    )
    public
    onlyMaintainer
    {
        // Generate hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(newUsername))));

        // Take the signer of the message
        address messageSigner = Call.recoverHash(hash, signature, 0);

        // Assert that the message signer is the _sender in the arguments
        require(messageSigner == userAddress);

        // Get the storage key for username in structure address => userData
        bytes32 keyHashUsername = keccak256("addressToUserData", "username", userAddress);

        // Set new username
        PROXY_STORAGE_CONTRACT.setString(keyHashUsername, newUsername);

        addOrChangeUsernameInternal(newUsername, userAddress);
    }


    /**
     * @notice          Function to link plasma and ethereum addresses, and set the note for the user
     *
     * @param           signature is the signature containing various information
     * @param           note is the note user wants to set
     * @param           externalSignature is the external signature user created
     */
    function setPlasma2EthereumAndNoteSigned(
        bytes signature,
        bytes note,
        bytes externalSignature
    )
    public
    onlyMaintainer
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum-plasma")),
            keccak256(abi.encodePacked(signature,note))));

        address ethereumAddress = Call.recoverHash(hash,externalSignature,0);

        require(ethereumAddress != address(0));

        // Link plasma 2 ethereum
        addPlasma2EthereumInternal(externalSignature, ethereumAddress);
        // Set note
        setNoteInternal(note, ethereumAddress);
    }


    /**
     * @notice          Function to read from mapping username => address
     *
     * @param           _username is the username of the user
     */
    function getUserName2UserAddress(
        string _username
    )
    public
    view
    returns (address)
    {
        bytes32 usernameBytes = stringToBytes32(_username);
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256("username2currentAddress", usernameBytes));
    }

    /**
     * @notice          Function to read mapping address => username
     *
     * @param           _userAddress is the address of the user
     */
    function getUserAddress2UserName(
        address _userAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256("address2username", _userAddress));
    }

//    /**
//     */
//    function deleteUser(
//        string userName
//    )
//    public
//    {
//        require(isMaintainer(msg.sender));
//        bytes32 userNameHex = stringToBytes32(userName);
//        address _ethereumAddress = username2currentAddress[userNameHex];
//        username2currentAddress[userNameHex] = address(0);
//
//        address2username[_ethereumAddress] = "";
//
//        bytes32 walletTag = address2walletTag[_ethereumAddress];
//        address2walletTag[_ethereumAddress] = bytes32(0);
//        walletTag2address[walletTag] = address(0);
//
//        address plasma = ethereum2plasma[_ethereumAddress];
//        ethereum2plasma[_ethereumAddress] = address(0);
//        PROXY_STORAGE_CONTRACT.deleteAddress()
//        plasma2ethereum[plasma] = address(0);
//
//        UserData memory userdata = addressToUserData[_ethereumAddress];
//        userdata.username = "";
//        userdata.fullName = "";
//        userdata.email = "";
//        addressToUserData[_ethereumAddress] = userdata;
//
//        notes[_ethereumAddress] = "";
//    }


    /**
     * @notice          Function to read from the mapping plasma=>ethereum
     *
     * @param           plasmaAddress is the plasma address we're searching eth address for
     */
    function getPlasmaToEthereum(
        address plasmaAddress
    )
    public
    view
    returns (address)
    {
        bytes32 keyHashPlasmaToEthereum = keccak256("plasma2ethereum", plasmaAddress);
        address ethereumAddress = PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum);

        return ethereumAddress != address(0) ? ethereumAddress : plasmaAddress;
    }

    /**
     * @notice          Function to read from the mapping ethereum => plasma
     *
     * @param           ethereumAddress is the ethereum address we're searching plasma address for
     *
     * @return          plasma address if exist otherwise 0x0 (address(0))
     */
    function getEthereumToPlasma(
        address ethereumAddress
    )
    public
    view
    returns (address)
    {
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", ethereumAddress);
        address plasmaAddress = PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma);

        return plasmaAddress != address(0) ? plasmaAddress : ethereumAddress;
    }


    /**
     * @notice          Function to check if the user exists
     *
     * @param           _userAddress is the address of the user
     *
     * @return          true if exists otherwise false
     */
    function checkIfUserExists(
        address _userAddress
    )
    public
    view
    returns (bool)
    {
        string memory username = PROXY_STORAGE_CONTRACT.getString(keccak256("address2username", _userAddress));
        bytes memory usernameInBytes = bytes(username);
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", _userAddress);
        address plasma = PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma);
        bytes memory savedNotes = PROXY_STORAGE_CONTRACT.getBytes(keccak256("notes", _userAddress));
        bytes32 walletTag = PROXY_STORAGE_CONTRACT.getBytes32(keccak256("address2walletTag", _userAddress));
        if(usernameInBytes.length == 0 || walletTag == 0 || plasma == address(0) || savedNotes.length == 0) {
            return false;
        }
        return true;
    }


    /**
     * @notice          Function to get user data
     *
     * @param           _userAddress is the ethereum address of the user
     */
    function getUserData(
        address _userAddress
    )
    public
    view
    returns (bytes)
    {
        //Generate the keys for the storage

        bytes32 keyHashUsername = keccak256("addressToUserData", "username", _userAddress);
        bytes32 keyHashFullName = keccak256("addressToUserData", "fullName", _userAddress);
        bytes32 keyHashEmail = keccak256("addressToUserData", "email", _userAddress);


        bytes32 username = stringToBytes32(PROXY_STORAGE_CONTRACT.getString(keyHashUsername));
        bytes32 fullName = stringToBytes32(PROXY_STORAGE_CONTRACT.getString(keyHashFullName));
        bytes32 email = stringToBytes32(PROXY_STORAGE_CONTRACT.getString(keyHashEmail));

        return (abi.encodePacked(username, fullName, email));
    }


    /**
     * @notice          Function to get the notes
     *
     * @param           keyAddress is the address of the key for the storage
     */
    function notes(
        address keyAddress
    )
    public
    view
    returns (bytes)
    {
        return PROXY_STORAGE_CONTRACT.getBytes(keccak256("notes", keyAddress));
    }


    /**
     * @notice          Function to read from the mapping userAddress => walletTag
     *
     * @param           keyAddress is the address user is searching wallet tag for
     */
    function address2walletTag(
        address keyAddress
    )
    public
    view
    returns (bytes32)
    {
        return PROXY_STORAGE_CONTRACT.getBytes32(keccak256("address2walletTag", keyAddress));
    }


    /**
     * @notice          Function to read from the mapping walletTag => userAddress
     *
     * @param           walletTag is the tag we wan't to get mapped address for
     */
    function walletTag2address(
        bytes32 walletTag
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256("walletTag2address", walletTag));
    }


    /**
     * @notice          Function to read from the mapping userAddress => username
     *
     * @param           keyAddress is the address we use as the key
     */
    function address2username(
        address keyAddress
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256("address2username", keyAddress));
    }


    /**
     * @notice          Function to read from the mapping username => currentAddress
     *
     * @param           _username is the hex username we want to get address for
     */
    function username2currentAddress(
        bytes32 _username
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256("username2currentAddress", _username));
    }

}
