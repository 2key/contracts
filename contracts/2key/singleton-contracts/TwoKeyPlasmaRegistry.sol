pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";

import "../interfaces/storage-contracts/ITwoKeyPlasmaRegistryStorage.sol";

import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../interfaces/ITwoKeyPlasmaReputationRegistry.sol";

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

    /**
     * @notice          Function to link username and address once signature is validated
     *
     * @param           plasmaAddress is the plasma address of the user
     * @param           username is username user want to set
     */
    function linkUsernameAndAddress(
        address plasmaAddress,
        string username
    )
    public
    onlyMaintainer
    {
        // Assert that this username is not pointing to any address
        require(getUsernameToAddress(username) == address(0));

        // Assert that this address is not pointing to any username
        bytes memory currentUserNameForThisAddress = bytes(getAddressToUsername(plasmaAddress));
        require(currentUserNameForThisAddress.length == 0);

        // Store _addressToUsername and  _usernameToAddress
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToUsername, plasmaAddress), username);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_usernameToAddress,username), plasmaAddress);

        // Give user registration bonus points
        ITwoKeyPlasmaReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaReputationRegistry"))
            .updateUserReputationScoreOnSignup(plasmaAddress);

        // Emit event that plasma and username are linked
        emitPlasma2Handle(plasmaAddress, username);
    }


    /**
     * @notice          Function to re-link username and address
     *
     * @param           plasmaAddress is the plasma address of the user
     * @param           username is username user want to set
     */
    function changeLinkedUsernameForAddress(
        address plasmaAddress,
        string username
    )
    public
    onlyMaintainer
    {
        // This can be called as many times as long plasma and ethereum are not linked
        // Afterwards, only changeUsername can be called
        require(plasma2ethereum(plasmaAddress) == address(0));

        // Assert that this username is not pointing to any address
        require(getUsernameToAddress(username) == address(0));

        // Store _addressToUsername and  _usernameToAddress
        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToUsername, plasmaAddress), username);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_usernameToAddress,username), plasmaAddress);

        // Emit event that plasma and username are linked
        emitPlasma2Handle(plasmaAddress, username);
    }


    /**
     * @notice          Function to map plasma2ethereum and ethereum2plasma
     *
     * @param           signature is the msg signed with users public address
     * @param           plasmaAddress is the user plasma address
     * @param           ethereumAddress is the ethereum address of user
     */
    function addPlasma2Ethereum(
        bytes signature,
        address plasmaAddress,
        address ethereumAddress
    )
    public
    onlyMaintainer
    {
        // Generate hash
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasmaAddress))));

        // Recover ethereumAddress from signature
        address recoveredEthereumAddress = Call.recoverHash(hash,signature,0);

        // Require that recoveredEthereumAddress is same as one passed in method argument
        require(recoveredEthereumAddress == ethereumAddress);

        // Require that plasma stored in contract for this ethereum address = address(0)
        address plasmaStoredInContract = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_ethereum2plasma,ethereumAddress));
        require(plasmaStoredInContract == address(0));

        // Require that ethereum stored in contract for this plasma address = address(0)
        address ethereumStoredInContract = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_plasma2ethereum, plasmaAddress));
        require(ethereumStoredInContract == address(0));

        // Save to the contract state mapping _ethereum2plasma nad _plasma2ethereum
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_plasma2ethereum, plasmaAddress), ethereumAddress);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_ethereum2plasma,ethereumAddress), plasmaAddress);

        // Emit event that plasma and ethereum addresses are being linked
        emitPlasma2Ethereum(plasmaAddress, ethereumAddress);
    }


    /**
     * @notice          Function where username can be changed
     *
     * @param           newUsername is the new username user wants to add
     * @param           userPublicAddress is the ethereum address of the user
     */
    function changeUsername(
        string newUsername,
        address userPublicAddress
    )
    public
    onlyMaintainer
    {
        // Get current username for this user
        string memory currentUsername = getAddressToUsername(plasmaAddress);

        // Get the plasma address for this ethereum address
        address plasmaAddress = ethereum2plasma(userPublicAddress);

        // Delete previous username mapping
        PROXY_STORAGE_CONTRACT.deleteAddress(keccak256(_usernameToAddress, currentUsername));

        require(getUsernameToAddress(newUsername) == address(0));

        PROXY_STORAGE_CONTRACT.setString(keccak256(_addressToUsername, plasmaAddress), newUsername);
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(_usernameToAddress, newUsername), plasmaAddress);

        emitUsernameChangedEvent(plasmaAddress, newUsername);
    }


    /**
     * @notice          Function where Congress on plasma can set moderator fee
     * @param           feePercentage is the feePercentage in uint (ether units)
     *                  example if you want to set 1%  then feePercentage = 1
     */
    function setModeratorFee(
        uint feePercentage
    )
    public
    onlyTwoKeyPlasmaCongress
    {
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_moderatorFeePercentage), feePercentage);
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
     * @notice          Function to validate if signature is valid
     * @param           signature is the signature
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
     * @notice          Function to return moderator fee
     */
    function getModeratorFee()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorFeePercentage));
    }

    /**
     * @notice          Function to get TwoKeyPlasmaCongress address
     */
    function getCongressAddress()
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getNonUpgradableContractAddress("TwoKeyPlasmaCongress");
    }

}
