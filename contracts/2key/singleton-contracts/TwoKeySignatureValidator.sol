pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../libraries/Utils.sol";
import "../interfaces/storage-contracts/ITwoKeySignatureValidatorStorage.sol";
import "../libraries/Call.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

contract TwoKeySignatureValidator is Upgradeable, Utils, ITwoKeySingletonUtils {

    using Call for *;
    bool initialized;
    // using constants to avoid typos
    string constant message = "bytes binding to name";

    // Pointer to storage contract
    ITwoKeySignatureValidatorStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function to simulate constructor
     * @param _twoKeySingletonRegistry is the address of TWO_KEY_SINGLETON_REGISTRY
     * @param _proxyStorage is the address of proxy of storage contracts
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeySignatureValidatorStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice Function to validate signature which will sign user data
     * @param _name is the name of user
     * @param _fullName is the full name of user
     * @param _email is the email of user
     * @param signature is the signature
     * @return if signature is good it will resolve address, otherwise it will be address(0)
     */
    function validateSignUserData(
        string _name,
        string _fullName,
        string _email,
        bytes signature
    )
    public
    pure
    returns (address)
    {
        string memory concatenatedValues = strConcat(_name,_fullName,_email);
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(message)),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        return message_signer;
    }

    /**
     * @notice Function to validate signature which will sign name
     * @param _name is user name to be signed
     * @param signature is signature containing that signed name
     * @return if signature is good it will resolve address, otherwise it will be address(0)
     */
    function validateSignName(
        string _name,
        bytes signature
    )
    public
    pure
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(message)),
            keccak256(abi.encodePacked(_name))));
        address eth_address = Call.recoverHash(hash,signature,0);
        return eth_address;
    }

    /**
     * @notice Function to validate signature which will sign wallet name
     * @param username is the username of the user
     * @param _username_walletName is = concat(username,'_',walletName)
     * @return if signature is good it will resolve address, otherwise it will be address(0)
     */
    function validateSignWalletName(
        string memory username,
        string memory _username_walletName,
        bytes signature
    )
    pure
    returns (address)
    {
        string memory concatenatedValues = strConcat(username,_username_walletName,"");

        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(message)),
            keccak256(abi.encodePacked(concatenatedValues))));
        address message_signer = Call.recoverHash(hash, signature, 0);
        return message_signer;
    }

    /**
     * @notice          Function to validate signature which will sign plasma2ethereum bindings
     * @param           plasmaAddress is the address
     * @param           signature is the signature
     * @return if signature is good it will resolve address, otherwise it will be address(0)
    */

    function validatePlasmaToEthereum(
        address plasmaAddress,
        bytes signature
    )
    public
    pure
    returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked("bytes binding to plasma address")),
                keccak256(abi.encodePacked(plasmaAddress))
            )
        );

        // Recover ethereumAddress from signature
        address recoveredEthereumAddress = Call.recoverHash(hash,signature,0);
        return recoveredEthereumAddress;
    }
}
