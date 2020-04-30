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
     * @param           _userEthereumAddress is the address of the user
     */
    function addName(
        string _username,
        address _userEthereumAddress
    )
    public
    onlyMaintainer
    {
        // Throw if user address already has some username assigned
        bytes memory currentUsernameAssignedToAddress = bytes(address2username(_userEthereumAddress));
        require(currentUsernameAssignedToAddress.length == 0);

        // Here also the validation for uniqueness for this username will be done
        addOrChangeUsernameInternal(_username, _userEthereumAddress);
    }


    /**
     * @notice          Function to map plasma and ethereum addresses for the user
     *                  The signature is generated by 2key-protocol function registry/index.ts
     *                  -> signEthereumToPlasma function
     * @param           signature is the message user signed with his ethereum address
     * @param           plasmaAddress is the plasma address of user which is signed by eth address
     * @param           ethereumAddress is the ethereum address of the user who signed the message
     *
     */
    function addPlasma2Ethereum(
        bytes signature,
        address plasmaAddress,
        address ethereumAddress
    )
    public
    onlyMaintainer
    {
        // Generate the hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasmaAddress))));

        // Recover ethereumAddress from the hash by signature
        address recoveredEthereumAddress = Call.recoverHash(hash,signature,0);

        // Require that ethereum addresses are matching
        require(ethereumAddress == recoveredEthereumAddress);

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
        if(usernameInBytes.length == 0 || plasma == address(0)) {
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
        string memory username = address2username(_userAddress);
        return (abi.encodePacked(stringToBytes32(username), bytes32(0), bytes32(0)));
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
