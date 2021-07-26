pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaParticipationRewardsStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

contract TwoKeyPlasmaParticipationRewards is Upgradeable {

    using Call for *;
    using SafeMath for *;

    bool initialized;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _userToEarningsPerEpoch = "userToEarningsPerEpoch";
    string constant _userToTotalAmountWithdrawn = "userToTotalAmountWithdrawn";
    string constant _userToTotalAmountInProgressOfWithdrawal = "userToTotalAmountInProgressOfWithdrawal";
    string constant _userToPendingEpochs = "userToPendingEpochs";
    string constant _userToWithdrawnEpochs = "userToWithdrawnEpochs";
    string constant _totalRewardsInEpoch = "totalRewardsInEpoch";
    string constant _totalRewardsToBeAssignedInEpoch = "totalRewardsToBeAssignedInEpoch";
    string constant _totalUsersInEpoch = "totalUsersInEpoch";
    string constant _userToSignature = "userToSignature";
    string constant _latestFinalizedEpochId = "latestEpochId";
    string constant _isEpochRegistrationFinalized = "isEpochRegistrationFinalized";
    string constant _epochInProgressOfRegistration = "epochInProgressOfRegistration";
    string constant _declaredEpochIds = "declaredEpochIds";
    string constant _signatoryAddress = "signatoryAddress";
    string constant _userToSignatureToAmountWithdrawn = "userToSignatureToAmountWithdrawn";

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
        require(isMaintainer(msg.sender));
        _;
    }


    modifier onlyTwoKeyPlasmaCongress {
        address congress = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getNonUpgradableContractAddress("TwoKeyPlasmaCongress");
        require(msg.sender == congress);
        _;
    }

    /**
     * @notice          Function to check if user is maintainer
     */
    function isMaintainer(address _address)
    internal
    view
    returns (bool)
    {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        return ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(_address);
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

    function setBytes(
        bytes32 key,
        bytes value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBytes(key,value);
    }

    function getBytes(
        bytes32 key
    )
    internal
    view
    returns (bytes)
    {
        return PROXY_STORAGE_CONTRACT.getBytes(key);
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

    function appendArrayToArray(
        bytes32 keyOfArray,
        uint [] arrayToAppend
    )
    internal
    {
        // Load current array
        uint [] memory currentArray = getUintArray(keyOfArray);

        uint newArrayLength = currentArray.length+ arrayToAppend.length;

        uint [] memory newArray = new uint[](newArrayLength);

        uint i;

        uint j = 0;

        // Append arrays
        for(i = 0; i < newArrayLength; i++) {
            if(i < currentArray.length) {
                newArray[i] = currentArray[i];
            } else {
                newArray[i] = arrayToAppend[j];
                j++;
            }

        }

        // Store new array in storage.
        PROXY_STORAGE_CONTRACT.setUintArray(
            keyOfArray,
            newArray
        );
    }

    function deleteUintArray(
        bytes32 key
    )
    internal
    {
        uint [] memory emptyArray = new uint[](0);
        PROXY_STORAGE_CONTRACT.setUintArray(key, emptyArray);
    }

    function setUintArray(
        bytes32 key,
        uint [] value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUintArray(key,value);
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
     * @notice          Function where TwoKeyPlasmaCongress can declare epoch ids
     */
    function declareEpochs(
        uint [] epochIds,
        uint [] totalRewardsPerEpoch
    )
    public
    onlyTwoKeyPlasmaCongress
    {
        uint[] memory declaredEpochIds = getDeclaredEpochIds();

        uint i;
        uint j;

        uint newArrayLen = declaredEpochIds.length + epochIds.length;
        uint [] memory newDeclaredEpochIds = new uint[](newArrayLen);

        for (i = 0; i < declaredEpochIds.length; i++) {
            newDeclaredEpochIds[i] = declaredEpochIds[i];
        }

        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");

        for (i = declaredEpochIds.length; i < newArrayLen; i++) {
            // Double check if epoch id is not already declared
            require(isEpochIdDeclared(epochIds[j]) == false);

            newDeclaredEpochIds[i] = epochIds[j];

            // Emit event that epoch is declared
            ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitEpochDeclared(
                epochIds[j],
                totalRewardsPerEpoch[j]
            );

            // Set in advance total rewards which can be distributed per epoch
            setUint(
                keccak256(_totalRewardsToBeAssignedInEpoch, epochIds[j]),
                totalRewardsPerEpoch[j]
            );

            j++;
        }

        // Set new declared epoch ids
        setUintArray(keccak256(_declaredEpochIds), newDeclaredEpochIds);
    }

    /**
     * @notice          Function to start epoch registration, this will in advance store
     *                  number of users to be rewarded and total rewards,
     *                  besides that, it will store epoch id as pending
     * @param           epochId is the id of epoch
     * @param           numberOfUsers is the number of users declared in this epoch
     */
    function registerEpoch(
        uint epochId,
        uint numberOfUsers
    )
    public
    onlyMaintainer
    {
        // Require that epoch is declared
        require(isEpochIdDeclared(epochId));
        // Require that there's no currently epoch in progress
        uint epochInProgress = getUint(keccak256(_epochInProgressOfRegistration));
        require(epochInProgress == 0);
        // Require that epoch id is equal to latest epoch submitted + 1
        require(epochId == getLatestFinalizedEpochId() + 1);

        // Emit event that epoch is registered
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitEpochRegistered(
            epochId,
            numberOfUsers
        );

        // Start registration process of this epoch
        setUint(
            keccak256(_epochInProgressOfRegistration),
            epochId
        );
    }


    /**
     * @notice          Function to register new participation mining epoch
     * @param           epochId is the id of the epoch being registered
     * @param           users is the array of users earned rewards in this epoch
     * @param           rewards is the array of rewards users earned in this epoch
     */
    function assignRewardsInActiveMiningEpoch(
        uint epochId,
        address [] users,
        uint [] rewards
    )
    public
    onlyMaintainer
    {
        require(epochId == getEpochIdInProgress());

        uint totalRewards;

        uint totalUsersInEpoch = getTotalUsersInEpoch(epochId);

        uint i;

        for(i = 0; i < users.length; i++) {
            bytes32 keyUserEarningsPerEpoch = keccak256(_userToEarningsPerEpoch, users[i], epochId);

            // Only if user is submitted first time for this epoch
            if(getUint(keyUserEarningsPerEpoch) == 0) {

                // Add rewards[i] to total rewards for this epoch in case this user is passed 1st time in this epoch
                totalRewards = totalRewards.add(rewards[i]);

                // Set user to earnings per epoch
                setUint(
                    keyUserEarningsPerEpoch,
                    rewards[i]
                );

                // Add epoch to array of pending epochs for selected user
                addEpochToPendingEpochsForUser(users[i], epochId);

                // Increment number of users in epoch
                totalUsersInEpoch++;

                // Emit event for each user who got rewarded for this epoch
                ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
                    .emitRewardsAssignedToUserInParticipationMiningEpoch(
                        epochId,
                        users[i],
                        rewards[i]
                );
            }
        }

        // Set total users in this epoch
        setUint(
            keccak256(_totalUsersInEpoch, epochId),
            totalUsersInEpoch
        );

        bytes32 keyHashTotalRewardsPerEpoch = keccak256(_totalRewardsInEpoch, epochId);

        // Add total rewards for this epoch
        setUint(
            keyHashTotalRewardsPerEpoch,
            totalRewards + getUint(keyHashTotalRewardsPerEpoch)
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
        // Require that epoch registration is not finalized
        require(isEpochRegistrationFinalized(epochId) == false);
        // Require that the epoch being finalized is the one in progress
        require(epochId == getEpochIdInProgress());

        require(getTotalRewardsPerEpoch(epochId) <= getTotalRewardsToBeAssignedInEpoch(epochId));

        setEpochRegistrationFinalized(epochId);

        // Emit event that epoch is finalized
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitEpochFinalized(
            epochId
        );

        // Set latest epoch id to be the one submitted
        setUint(
            keccak256(_latestFinalizedEpochId),
            epochId
        );

        // Set epoch in progress of registration to be 0
        setUint(
            keccak256(_epochInProgressOfRegistration),
            0
        );
    }


    /**
     * @notice          Function to redeclare total rewards amount for epoch currently in progress
     * @param           rewardsAmount is new amount total for that epoch
     */
    function redeclareRewardsAmountForEpoch(
        uint epochId,
        uint rewardsAmount
    )
    public
    onlyTwoKeyPlasmaCongress
    {
        // Require that epoch exists
        require(epochId > 0);
        // Get current epoch in progress
        require(epochId == getEpochIdInProgress());
        // Redeclare total amount to be assigned in epoch
        setUint(
            keccak256(_totalRewardsToBeAssignedInEpoch, epochId),
            rewardsAmount
        );
    }

    /**
     * @notice          Function to submit signature for user withdrawal
     */
    function submitSignatureForUserWithdrawal(
        address userPublicAddress,
        uint totalRewardsPending,
        bytes signature
    )
    public
    onlyMaintainer
    {
        address userPlasma = ITwoKeyPlasmaRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry"))
            .ethereum2plasma(userPublicAddress);

        // Require that there's no epoch in progress of submitting
        require(getEpochIdInProgress() == 0);

        // Require that user doesn't have any pending signatures
        bytes memory pendingSignature = getBytes(keccak256(_userToSignature,userPlasma));
        require(pendingSignature.length == 0);

        // Require that user withdrawn his previous rewards if he started withdraw process
        require(getHowMuchUserHaveInProgressOfWithdrawal(userPlasma) == 0);

        // Recover signer of the message with user PUBLIC address
        address messageSigner = recoverSignature(
            userPublicAddress,
            totalRewardsPending,
            signature
        );

        // For security we require that message is signed by different maintainer than one sending this tx
        require(messageSigner == getSignatoryAddress());

        // get pending epoch ids user has
        uint [] memory userPendingEpochIds = getPendingEpochsForUser(userPlasma);

        uint i;
        uint len = userPendingEpochIds.length;

        // Get sum of all pending epochs
        uint sumOfRewards;

        // Calculate sum on all users rewards
        for(i=0 ; i < len ; i++) {
            sumOfRewards = sumOfRewards.add(
                getUserEarningsPerEpoch(
                    userPlasma,
                    userPendingEpochIds[i]
                )
            );
        }

        // Require that sum of pending rewards is equaling amount of rewards signed
        require(sumOfRewards == totalRewardsPending);

        // Append pending epochs to withdrawn epochs
        appendArrayToArray(
            keccak256(_userToWithdrawnEpochs, userPlasma),
            userPendingEpochIds
        );

        // Delete array with pending epochs
        deleteUintArray(
            keccak256(
                _userToPendingEpochs,
                userPlasma
            )
        );

        // Set user signature ready for withdrawal
        setBytes(
            keccak256(_userToSignature,userPlasma),
            signature
        );

        // Set user pending rewards are now in progress of withdrawal
        setUint(
            keccak256(_userToTotalAmountInProgressOfWithdrawal,userPlasma),
            totalRewardsPending
        );

    }

    /**
     * @notice          Function which will mark that user finished withdrawal on mainchain
     * @param           userPlasma is the address of user
     * @param           signature is the signature user used to withdraw on mainchain
     */
    function markUserFinishedWithdrawalFromMainchainWithSignature(
        address userPlasma,
        bytes signature
    )
    public
    onlyMaintainer
    {
        bytes memory pendingSignature = getUserPendingSignature(userPlasma);
        // Require that user signature is matching the one stored on the contract
        require(keccak256(pendingSignature) == keccak256(signature));

        // Remove signature so user can withdraw again once he earns some rewards
        PROXY_STORAGE_CONTRACT.deleteBytes(
            keccak256(_userToSignature, userPlasma)
        );

        bytes32 totalUserWithdrawalsKeyHash = keccak256(_userToTotalAmountWithdrawn, userPlasma);

        uint totalWithdrawn = getUint(totalUserWithdrawalsKeyHash);

        // Add to total withdrawn by user
        setUint(
            totalUserWithdrawalsKeyHash,
            totalWithdrawn.add(getUint(keccak256(_userToTotalAmountInProgressOfWithdrawal, userPlasma)))
        );

        // Get how much user had pending in withdrawal
        uint pendingOfWithdrawal = getHowMuchUserHaveInProgressOfWithdrawal(userPlasma);

        // Set that pending was withdrawn with signature
        setAmountWithdrawnWithSignature(
            userPlasma,
            signature,
            pendingOfWithdrawal
        );

        // Set that user has 0 in progress of withdrawal
        setUint(
            keccak256(_userToTotalAmountInProgressOfWithdrawal, userPlasma),
            0
        );
    }

    /**
     * @notice          Function where congress can set signatory address
     *                  and that's the only address eligible to sign the rewards messages
     * @param           signatoryAddress is the address which will be used to sign rewards
     */
    function setSignatoryAddress(
        address signatoryAddress
    )
    public
    onlyTwoKeyPlasmaCongress
    {
        PROXY_STORAGE_CONTRACT.setAddress(
            keccak256(_signatoryAddress),
            signatoryAddress
        );
    }


    /**
     * @notice          Function where maintainer can check who signed the message
     * @param           userAddress is the address of user for who we signed message
     * @param           totalRewardsPending is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignature(
        address userAddress,
        uint totalRewardsPending,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked('bytes binding user rewards')),
                keccak256(abi.encodePacked(userAddress,totalRewardsPending))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }

    /**
     * @notice          Internal function to set the amount user has withdrawn
                        using specific signature
     * @param           userPlasma is the address of user
     * @param           signature is the signature created by user
     * @param           amountWithdrawn is the amount user withdrawn using that signature
     */
    function setAmountWithdrawnWithSignature(
        address userPlasma,
        bytes signature,
        uint amountWithdrawn
    )
    internal
    {
        setUint(
            keccak256(_userToSignatureToAmountWithdrawn, userPlasma, signature),
            amountWithdrawn
        );
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
     * @notice          Function to return total amount user has pending
     * @param           user is the user address
     */
    function getUserTotalPendingAmount(
        address user
    )
    public
    view
    returns (uint)
    {
        uint pendingAmount = 0;

        uint [] memory pendingEpochs = getPendingEpochsForUser(user);
        uint i = 0;
        for(i = 0; i < pendingEpochs.length; i++) {
            pendingAmount = pendingAmount.add(getUserEarningsPerEpoch(user, pendingEpochs[i]));
        }
        return (
            pendingAmount
        );
    }


    /**
     * @notice          Function to return total amount user has withdrawn
     * @param           user is the user address
     */
    function getUserTotalWithdrawnAmount(
        address user
    )
    public
    view
    returns (uint)
    {
        uint withdrawnAmount = 0;

        uint [] memory withdrawnEpochs = getWithdrawnEpochsForUser(user);
        uint i = 0;
        for(i = 0; i < withdrawnEpochs.length; i++) {
            withdrawnAmount = withdrawnAmount.add(getUserEarningsPerEpoch(user, withdrawnEpochs[i]));
        }
        return (
            withdrawnAmount
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
            keccak256(_totalRewardsInEpoch, epochId)
        );
    }

    /**
     * @notice          Function to get latest submitted epoch id
     */
    function getLatestFinalizedEpochId()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_latestFinalizedEpochId));
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

    /**
     * @notice          Function to retrieve signature for user which is in progress of withdrawal
     * @param           user is the user address
     */
    function getUserPendingSignature(
        address user
    )
    public
    view
    returns (bytes)
    {
        return getBytes(keccak256(_userToSignature, user));
    }



    /**
     * @notice          Function to check amount user has withdrawn using specific signature
     * @param           user is the address of the user
     * @param           signature is the signature signed by maintainer
     */
    function getAmountUserWithdrawnUsingSignature(
        address user,
        bytes signature
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_userToSignatureToAmountWithdrawn, user, signature)
        );
    }

    /**
     * @notice          Function to check how much user have in progress of withdrawal
     * @param           user is the address of the user
     */
    function getHowMuchUserHaveInProgressOfWithdrawal(
        address user
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_userToTotalAmountInProgressOfWithdrawal, user));
    }

    /**
     * @notice          Function to get epoch id which is in progress
     */
    function getEpochIdInProgress()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_epochInProgressOfRegistration));
    }

    /**
     * @notice          Function to get total number of users in epoch
     * @param           epochId is the ID of the epoch
     */
    function getTotalUsersInEpoch(
        uint epochId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_totalUsersInEpoch,epochId));
    }

    /**
     * @notice          Function to get total rewards to be assigned in the epoch
     * @param           epochId is the ID of the epoch
     */
    function getTotalRewardsToBeAssignedInEpoch(
        uint epochId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_totalRewardsToBeAssignedInEpoch, epochId));
    }

    function getDeclaredEpochIds()
    public
    view
    returns (uint[])
    {
        return getUintArray(keccak256(_declaredEpochIds));
    }

    /**
     * @notice          Function to fetch signatory address
     */
    function getSignatoryAddress()
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_signatoryAddress));
    }


    function isEpochIdDeclared(
        uint epochId
    )
    public
    view
    returns (bool)
    {
        // Get declared epochs
        uint [] memory declaredEpochIds = getDeclaredEpochIds();
        return declaredEpochIds.length >= epochId;
    }
}
