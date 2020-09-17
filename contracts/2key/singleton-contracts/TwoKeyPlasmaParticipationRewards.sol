pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaParticipationRewardsStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

contract TwoKeyPlasmaParticipationRewards is Upgradeable {

    using Call for *;
    using SafeMath for *;

    bool initialized;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _userToEarningsPerEpoch = "userToEarningsPerEpoch";
    string constant _userToTotalAmountPending = "userToTotalAmountPending";
    string constant _userToTotalAmountWithdrawn = "userToTotalAmountWithdrawn";
    string constant _userToPendingEpochs = "userToPendingEpochs";
    string constant _userToWithdrawnEpochs = "userToWithdrawnEpochs";
    string constant _totalRewardsPerEpoch = "totalRewardsPerEpoch";
    string constant _userToSignature = "userToSignature";
    string constant _latestEpochId = "latestEpochId";
    string constant _isEpochRegistrationFinalized = "isEpochRegistrationFinalized";

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
        require(isEpochRegistrationFinalized(epochId) == false);
        require(epochId > getLatestEpochId());

        uint totalRewards;
        uint i;

        for(i = 0; i < users.length; i++) {
            bytes32 keyUserEarningsPerEpoch = keccak256(_userToEarningsPerEpoch, users[i], epochId);

            // Only if user is submitted first time for this epoch
            if(getUint(keyUserEarningsPerEpoch) == 0) {

                // Add rewards[i] to total rewards for this epoch in case this user is passed 1st time in this epoch
                totalRewards = totalRewards.add(rewards[i]);

                // Generate key for user pending balance
                bytes32 keyUserPendingBalance = keccak256(_userToTotalAmountPending, users[i]);

                // Get current user pending balance
                uint userCurrentPendingBalance = getUint(keyUserPendingBalance);

                // Set user to earnings per epoch
                setUint(
                    keyUserEarningsPerEpoch,
                    rewards[i]
                );

                // Add to user pending balance amount he earned
                setUint(
                    keyUserPendingBalance,
                    userCurrentPendingBalance.add(rewards[i])
                );

                // Add epoch to array of pending epochs for selected user
                addEpochToPendingEpochsForUser(users[i], epochId);

                // Emit event for each user who got rewarded for this epoch
                ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitUserRewardedInParticipationMiningEpoch(
                    epochId,
                    users[i],
                    rewards[i]
                );
            }
        }

        bytes32 keyHashTotalRewardsPerEpoch = keccak256(_totalRewardsPerEpoch, epochId);

        // Add total rewards for this epoch
        setUint(
            keyHashTotalRewardsPerEpoch,
            totalRewards + getUint(keyHashTotalRewardsPerEpoch)
        );

        // Set latest epoch id to be the one submitted
        setUint(
            keccak256(_latestEpochId),
            epochId
        );
    }

    /**
     * @notice          Function where maintainer after  he finishes registration for epochId
     *                  will submit that it's finalized
     * @param           epochId is the id of the epoch
     */
    function finalizeEpoch(
        uint epochId
    )
    public
    onlyMaintainer
    {
        require(isEpochRegistrationFinalized(epochId) == false);
        setEpochRegistrationFinalized(epochId);
    }




    /**
     * @notice          Function to submit signature for user withdrawal
     */
    function submitSignatureForUserWithdrawal(
        address user,
        uint [] epochIds,
        uint totalRewardsPending,
        bytes signature
    )
    public
    onlyMaintainer
    {
        // TODO : Verify signature
//        address [] memory userPendingEpochIds = getPendingEpochsForUser(user);
//        uint i;
//        uint len = userPendingEpochIds.length;
//
//        uint sumOfRewards;
//        // Require that all pending epoch ids are covered
//        for(i=0 ; i < len ; i++) {
//            require(userPendingEpochIds[i] == epochIds[i]);
//            sumOfRewards = sumOfRewards.add(getUser)
//        }



    }

    function verifySignatureAndData(
        address userAddress,
        uint totalRewardsPending,
        bytes signature
    )
    public
    view
    returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(userAddress)),keccak256(abi.encodePacked(totalRewardsPending))));

        // Recover signer message from signature
        address recoveredSignerOfMessage = Call.recoverHash(hash,signature,0);

        // Check if message was properly recovered and signed by maintainer
        bool isSignedByMaintainer = recoveredSignerOfMessage == msg.sender ? true : false;

        // Return if message is signed by maintainer
        return isSignedByMaintainer;
    }



    /**
     * @notice          Internal function to set epoch registration is finalized
     * @param           epochId is the id of the epoch
     */
    function setEpochRegistrationFinalized(
        uint epochId
    )
    internal
    {
        setBool(
            keccak256(_isEpochRegistrationFinalized, epochId),
            true
        );
    }

    /**
     * @notice          Function to get user earnings per epoch
     * @param           user is the address of user
     * @param           epochId is the id of the epoch for this user
     */
    function getUserEarningsPerEpoch(
        address user,
        uint epochId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_userToEarningsPerEpoch, user, epochId));
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

    /**
     * @notice          Function to get epochs user already withdrawn
     * @param           user is the user address
     */
    function getWithdrawnEpochsForUser(
        address user
    )
    public
    view
    returns (uint[])
    {
        return getUintArray(keccak256(_userToWithdrawnEpochs, user));
    }

    /**
     * @notice          Function to get total rewards for epoch
     * @param           epochId is the ID of the epoch
     */
    function getTotalRewardsPerEpoch(
        uint epochId
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_totalRewardsPerEpoch, epochId)
        );
    }

    /**
     * @notice          Function to get latest submitted epoch id
     */
    function getLatestEpochId()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_latestEpochId));
    }

    /**
     * @notice          Function to return if epoch id is finished with registration
     * @param           epochId is id of the epoch
     */
    function isEpochRegistrationFinalized(
        uint epochId
    )
    public
    view
    returns (bool)
    {
        return getBool(
            keccak256(_isEpochRegistrationFinalized, epochId)
        );
    }

}
