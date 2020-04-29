pragma solidity ^0.4.24;

import "../libraries/Call.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../libraries/Utils.sol";
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyRegistryStorage.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";


/**
 * @title           TwoKeyRegistry contract which is used for users registration
 * @notice          Completely managed by trusted maintainers
 * @author          Nikola Madjarevic (@madjarevicn)
 */
contract TwoKeyRegistry is Upgradeable, Utils, ITwoKeySingletonUtils {

    using Call for *;

    bool initialized;

    string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";

    ITwoKeyRegistryStorage public PROXY_STORAGE_CONTRACT;




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

        // Create key hashes for mappings for username2currentAddress and address2username
        bytes32 keyHashUserNameToAddress = keccak256("username2currentAddress", usernameBytes32);
        bytes32 keyHashAddressToUserName = keccak256("address2username", _userAddress);

        // Assert that username is not taken
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashUserNameToAddress) == address(0));

        // Set mapping address => username
        PROXY_STORAGE_CONTRACT.setString(keyHashAddressToUserName, _username);

        // Set mapping username => address
        PROXY_STORAGE_CONTRACT.setAddress(keyHashUserNameToAddress, _userAddress);
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
        address _userEthereumAddress
    )
    public
    onlyMaintainer
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

        // Throw if user address already has some username assigned
        bytes memory currentUsernameAssignedToAddress = bytes(address2username(_userAddress));
        require(currentUsernameAssignedToAddress.length == 0);

        // Generate the keys for the storage contract
        bytes32 keyHashUsername = keccak256("addressToUserData", "username", _userAddress);
        bytes32 keyHashFullName = keccak256("addressToUserData", "fullName", _userAddress);
        bytes32 keyHashEmail = keccak256("addressToUserData", "email", _userAddress);

        // Set the values
        PROXY_STORAGE_CONTRACT.setString(keyHashUsername, _username);
        PROXY_STORAGE_CONTRACT.setString(keyHashFullName, _fullName);
        PROXY_STORAGE_CONTRACT.setString(keyHashEmail, _email);

        // Here also the validation for uniqueness for this username will be done
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
        // Get user address from the storage for this username
        address usersAddress = getUserName2UserAddress(username);

        // Validate that it's same user
        require(usersAddress == _address);

        string memory concatenatedValues = strConcat(username,_username_walletName,"");

        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to name")),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        require(message_signer == _address);

        bytes32 walletTag = stringToBytes32(_username_walletName);

        // Require that this wallet tag is not assigned to any other address
        bytes32 keyHashWalletTag2Address = keccak256("walletTag2address", walletTag);
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashWalletTag2Address) == address(0));

        // Save in the contract state this walletTag2address mapping
        PROXY_STORAGE_CONTRACT.setAddress(keyHashWalletTag2Address, _address);

        // Require that address doesn't have any previously assigned walletTag
        bytes32 keyHashAddress2WalletTag = keccak256("address2walletTag", _address);
        require(PROXY_STORAGE_CONTRACT.getBytes32(keyHashAddress2WalletTag) == bytes32(0));

        // Save in the contract state this address2walletTag mapping
        PROXY_STORAGE_CONTRACT.setBytes32(keyHashAddress2WalletTag, walletTag);
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
     *                  The signature is generated by 2key-protocol function registry/index.ts
     *                  -> signPlasma2Ethereum function
     * @param           signature is the message user signed so we can take his plasma_address
     * @param           ethereumAddress is the ethereum address of the user who signed the message
     *
     */
    function addPlasma2Ethereum(
        bytes signature,
        address ethereumAddress
    )
    public
    onlyMaintainer
    {
        // Generate the hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to ethereum address")),keccak256(abi.encodePacked(ethereumAddress))));

        // Recover plasma address from the hash by signature
        address plasmaAddress = Call.recoverHash(hash,signature,0);

        // Generate the keys for the storage for 2 mappings we want to check and update
        bytes32 keyHashPlasmaToEthereum = keccak256("plasma2ethereum", plasmaAddress);
        bytes32 keyHashEthereumToPlasma = keccak256("ethereum2plasma", ethereumAddress);

        // Assert that both of this address currently don't exist in our system
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashPlasmaToEthereum) == address(0));
        require(PROXY_STORAGE_CONTRACT.getAddress(keyHashEthereumToPlasma) == address(0));

        // Store the addresses
        PROXY_STORAGE_CONTRACT.setAddress(keyHashPlasmaToEthereum, ethereumAddress);
        PROXY_STORAGE_CONTRACT.setAddress(keyHashEthereumToPlasma, plasmaAddress);
    }


    /**
     * @notice          Function where username can be changed
     *
     * @param           newUsername is the new username user wants to add
     * @param           userPublicAddress is the ethereum address of the user
     * @param           signature is the signature of the user
     */
    function changeUsername(
        string newUsername,
        address userPublicAddress,
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
        require(messageSigner == userPublicAddress);

        // Get current username which is allocated to this address
        string memory currentUsername = address2username(userPublicAddress);

        // Delete current username=>address mapping
        PROXY_STORAGE_CONTRACT.setAddress(keccak256("username2currentAddress", stringToBytes32(currentUsername)), address(0));

        // Get the storage key for username in structure address => userData
        bytes32 keyHashUsername = keccak256("addressToUserData", "username", userPublicAddress);

        // Set new username
        PROXY_STORAGE_CONTRACT.setString(keyHashUsername, newUsername);

        addOrChangeUsernameInternal(newUsername, userPublicAddress);

        // Emit event on TwoKeyEventSource that the username is changed
        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"))
            .emitHandleChangedEvent(
                getEthereumToPlasma(userPublicAddress),
                newUsername
            );
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
