pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";

import "../interfaces/storage-contracts/ITwoKeyPlasmaRegistryStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../libraries/Call.sol";


contract TwoKeyPlasmaRegistry is Upgradeable {

    using Call for *;


    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _addressToUsername = "addressToUsername";
    string constant _usernameToAddress = "usernameToAddress";
    string constant _plasma2ethereum = "plasma2ethereum";
    string constant _ethereum2plasma = "ethereum2plasma";
    string constant _moderatorFeePercentage = "moderatorFeePercentage";
    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaEventSource = "TwoKeyPlasmaEventSource";

    ITwoKeyPlasmaRegistryStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice          Modifier which will be used to restrict calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }


    /**
     * @notice          Modifier to restrict calls to TwoKeyPlasmaCongress
     */
    modifier onlyTwoKeyPlasmaCongress {
        address twoKeyCongress = getCongressAddress();
        require(msg.sender == address(twoKeyCongress));
        _;
    }


    /**
     * @notice          Function used as replacement for constructor, can be called only once
     *
     * @param           _twoKeyPlasmaSingletonRegistry is the address of TwoKeyPlasmaSingletonRegistry
     * @param           _proxyStorage is the address of proxy for storage
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaRegistryStorage(_proxyStorage);
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_moderatorFeePercentage), 2);
        initialized = true;
    }


    /**
     * @notice          Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }


    /**
     * @notice          Function to link username and address once signature is validated
     *
     * @param           signature is the signature user created
     * @param           plasmaAddress is the plasma address of the user
     * @param           username is username user want to set
     */
    function linkUsernameAndAddress(
        bytes signature,
        address plasmaAddress,
        string username
    )
    public
    onlyMaintainer
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasmaAddress))));
        require (signature.length == 65);
        address plasma = Call.recoverHash(hash,signature,0);
        require(plasma == plasmaAddress);

        require(getUsernameToAddress(username) == address(0));
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToUsername, plasmaAddress), username);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_usernameToAddress,username), plasmaAddress);

        emitPlasma2Handle(plasmaAddress, username);
    }


    /**

     */
    function add_plasma2ethereum(
        address plasma_address,
        bytes sig
    )
    public
    onlyMaintainer
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasma_address))));
        require (sig.length == 65);

        address eth_address = Call.recoverHash(hash,sig,0);

        address ethereum = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_plasma2ethereum, plasma_address));
        require(ethereum == address(0) || ethereum == eth_address);

        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_plasma2ethereum, plasma_address), eth_address);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_ethereum2plasma,eth_address), plasma_address);

        emitPlasma2Ethereum(plasma_address, eth_address);
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

        address plasmaAddress = ethereum2plasma(userPublicAddress);

        require(getUsernameToAddress(newUsername) == address(0));

        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToUsername, plasmaAddress), newUsername);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_usernameToAddress, newUsername), plasmaAddress);

        emitUsernameChangedEvent(plasmaAddress, newUsername);
    }

    function emitUsernameChangedEvent(
        address plasmaAddress,
        string newHandle
    )
    internal
    {
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaEventSource);
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitHandleChangedEvent(plasmaAddress, newHandle);
    }


    function emitPlasma2Ethereum(
        address plasma,
        address ethereum
    )
    internal
    {
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaEventSource);
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitPlasma2EthereumEvent(plasma, ethereum);
    }

    function emitPlasma2Handle(
        address plasma,
        string handle
    )
    internal
    {
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaEventSource);
        ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitPlasma2HandleEvent(plasma, handle);
    }

    function plasma2ethereum(
        address _plasma
    )
    public
    view
    returns (address) {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_plasma2ethereum, _plasma));
    }

    function ethereum2plasma(
        address _ethereum
    )
    public
    view
    returns (address) {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_ethereum2plasma, _ethereum));
    }

    function getAddressToUsername(
        address _address
    )
    public
    view
    returns (string)
    {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToUsername,_address));
    }

    function getUsernameToAddress(
        string _username
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_usernameToAddress, _username));
    }

    /**
     * @notice Function to validate if signature is valid
     * @param signature is the signature
     */
    function recover(
        bytes signature
    )
    public
    view
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
            keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
        address recoveredAddress = Call.recoverHash(hash, signature, 0);
        return recoveredAddress;
    }

    /**
     * @notice Function where Congress on plasma can set moderator fee
     * @param feePercentage is the feePercentage in uint (ether units)
     * example if you want to set 1%  then feePercentage = 1
     */
    function setModeratorFee(
        uint feePercentage
    )
    public
    onlyTwoKeyPlasmaCongress
    {
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_moderatorFeePercentage), feePercentage);
    }

    /**
     * @notice Function to return moderator fee
     */
    function getModeratorFee()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorFeePercentage));
    }

    function getCongressAddress()
    public
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getNonUpgradableContractAddress("TwoKeyPlasmaCongress");
    }

}
