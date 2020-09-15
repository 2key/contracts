pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaParticipationRewardsStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../libraries/SafeMath.sol";

contract TwoKeyPlasmaParticipationRewards is Upgradeable {

    using SafeMath for *;

    bool initialized;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _userToEarningsPerEpoch = "userToEarningsPerEpoch";
    string constant _userToTotalAmountPending = "userToTotalAmountPending";
    string constant _userToTotalAmountWithdrawn = "userToTotalAmountWithdrawn";
    string constant _userToPendingEpochs = "userToPendingEpochs";
    string constant _userToWithdrawnEpochs = "userToWithdrawnEpochs";
    string constant _userToSignature = "userToSignature";
    string constant _latestEpochId = "latestEpochId";
    string constant _isEpochIdExisting = "isEpochIdExisting";

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaParticipationRewardsStorage PROXY_STORAGE_CONTRACT;



    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaParticipationRewardsStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice          Modifier which will be used to restrict calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }


    function addNewEpoch(
        uint epochId
    )
    internal
    {
        setBool(
            keccak256(_isEpochIdExisting, epochId),
            true
        );
    }


    function addEpochToPendingEpochsForUser(
        address user,
        uint epochId
    )
    internal
    {
        appendToUintArray(
            keccak256(_userToPendingEpochs, user),
            epochId
        );
    }


    // Internal wrapper method to manipulate storage contract
    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }

    // Internal wrapper method to manipulate storage contract
    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getUintArray(
        bytes32 key
    )
    internal
    view
    returns (uint[])
    {
        return PROXY_STORAGE_CONTRACT.getUintArray(key);
    }

    function appendToUintArray(
        bytes32 keyOfArray,
        uint elementToAppend
    )
    internal
    {
        // Load current array
        uint [] memory currentArray = getUintArray(keyOfArray);

        uint newArrayLength = currentArray.length+1;

        uint [] memory newArray = new uint[](newArrayLength);

        uint i;

        for(i = 0; i < currentArray.length; i++) {
            newArray[i] = currentArray[i];
        }

        // Append element to end of array
        newArray[i] = elementToAppend;

        // Store new array in storage.
        PROXY_STORAGE_CONTRACT.setUintArray(
            keyOfArray,
            newArray
        );
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
     * @notice          Function to register new participation mining epoch
     * @param           epochId is the id of the epoch being registered
     * @param           users is the array of users earned rewards in this epoch
     * @param           rewards is the array of rewards users earned in this epoch
     */
    function registerParticipationMiningEpoch(
        uint epochId,
        address [] users,
        uint [] rewards
    )
    public
    onlyMaintainer
    {
        uint totalRewards;
        // require epoch id doesn't exist
        require(isEpochIdExisting(epochId) == false);
        // add this epoch
        addNewEpoch(epochId);

        uint i;

        for(i = 0; i < users.length; i++) {
            bytes32 keyUserPendingBalance = keccak256(_userToTotalAmountPending, users[i]);
            uint userCurrentPendingBalance = getUint(keyUserPendingBalance);

            // Add to user pending balance amount he earned
            setUint(
                keyUserPendingBalance,
                userCurrentPendingBalance.add(rewards[i])
            );

            // Set user to earnings per epoch
            setUint(
                keccak256(_userToEarningsPerEpoch, users[i], epochId),
                rewards[i]
            );

            addEpochToPendingEpochsForUser(users[i], epochId);
        }

        // Emit event for this epoch so on the graph we can do checksums as well
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitAddedParticipationMiningEpoch(
            epochId,
            users,
            rewards
        );
    }



    function submitSignatureForUserWithdrawal(

    )
    onlyMaintainer
    {

    }



    /**
     * @notice          Function to return if epoch id is already existing
     * @param           epochId is id of the epoch
     */
    function isEpochIdExisting(
        uint epochId
    )
    public
    view
    returns (bool)
    {
        return getBool(
            keccak256(_isEpochIdExisting, epochId)
        );
    }

    /**
     * @notice          Function to return statistics per user
     * @param           user is the user address
     */
    function getUserTotalPendingAndWithdrawn(
        address user
    )
    public
    view
    returns (uint,uint)
    {
        return (
        getUint(keccak256(_userToTotalAmountPending, user)),
        getUint(keccak256(_userToTotalAmountWithdrawn, user))
        );
    }

    /**
     * @notice          Function to get pending epochs for user
     * @param           user is the user address
     */
    function getPendingEpochsForUser(
        address user
    )
    public
    view
    returns (uint[])
    {
        return getUintArray(keccak256(_userToPendingEpochs, user));
    }


}
