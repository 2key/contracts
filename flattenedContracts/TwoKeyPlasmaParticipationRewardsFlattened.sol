pragma solidity ^0.4.13;

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyPlasmaEventSource {
    function emitPlasma2EthereumEvent(address _plasma, address _ethereum) public;

    function emitPlasma2HandleEvent(address _plasma, string _handle) public;

    function emitCPCCampaignCreatedEvent(address proxyCPCCampaignPlasma, address contractorPlasma) public;

    function emitConversionCreatedEvent(address campaignAddressPublic, uint conversionID, address contractor, address converter) public;

    function emitConversionExecutedEvent(uint conversionID) public;

    function emitConversionRejectedEvent(uint conversionID, uint statusCode) public;

    function emitCPCCampaignMirrored(address proxyAddressPlasma, address proxyAddressPublic) public;

    function emitHandleChangedEvent(address _userPlasmaAddress, string _newHandle) public;

    function emitConversionPaidEvent(uint conversionID) public;

    function emitAddedPendingRewards(address campaignPlasma, address influencer, uint amountOfTokens) public;

    function emitRewardsAssignedToUserInParticipationMiningEpoch(uint epochId, address user, uint reward2KeyWei) public;

    function emitEpochDeclared(uint epochId, uint totalRewardsInEpoch) public;

    function emitEpochRegistered(uint epochId, uint numberOfUsers) public;

    function emitEpochFinalized(uint epochId) public;

    function emitPaidPendingRewards(
        address influencer,
        uint amountNonRebalancedReferrerEarned,
        uint amountPaid,
        address[] campaignsPaid,
        uint [] earningsPerCampaign,
        uint feePerReferrer2KEY
    ) public;

}

contract ITwoKeyPlasmaRegistry {

    function plasma2ethereum(
        address _plasma
    )
    public
    view
    returns (address);


    function ethereum2plasma(
        address _ethereum
    )
    public
    view
    returns (address);

    function getModeratorFee()
    public
    view
    returns (uint);
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract ITwoKeyPlasmaParticipationRewardsStorage is IStructuredStorage {

}

library Call {
    function params0(address c, bytes _method) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x04, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params1(address c, bytes _method, uint _val) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)
        // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x24, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params2(address c, bytes _method, uint _val1, uint _val2) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val1)
            mstore(add(ptr,0x24), _val2)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x44, // Inputs are 4 bytes for signature and 2 uint256
            ptr,  //Store output over input
            0x20) //Outputs are 1 uint long

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x20)) // Set storage pointer to new space
        }
    }

    function loadAddress(bytes sig, uint idx) public pure returns (address) {
        address influencer;
        idx += 20;
        assembly
        {
            influencer := mload(add(sig, idx))
        }
        return influencer;
    }

    function loadUint8(bytes sig, uint idx) public pure returns (uint8) {
        uint8 weight;
        idx += 1;
        assembly
        {
            weight := mload(add(sig, idx))
        }
        return weight;
    }


    function recoverHash(bytes32 hash, bytes sig, uint idx) public pure returns (address) {
        // same as recoverHash in utils/sign.js
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        require (sig.length >= 65+idx, 'bad signature length');
        idx += 32;
        bytes32 r;
        assembly
        {
            r := mload(add(sig, idx))
        }

        idx += 32;
        bytes32 s;
        assembly
        {
            s := mload(add(sig, idx))
        }

        idx += 1;
        uint8 v;
        assembly
        {
            v := mload(add(sig, idx))
        }
        if (v >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
            v -= 32;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; // 32 is the number of bytes in the following hash
            hash = keccak256(abi.encodePacked(prefix, hash));
        }
        if (v <= 1) v += 27;
        require(v==27 || v==28,'bad sig v');
        //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L57
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'bad sig s');
        return ecrecover(hash, v, r, s);

    }

    function recoverSigMemory(bytes sig) private pure returns (address[], address[], uint8[], uint[], uint) {
        uint8 version = loadUint8(sig, 0);
        uint msg_len = (version == 1) ? 1+65+20 : 1+20+20;
        uint n_influencers = (sig.length-21) / (65+msg_len);
        uint8[] memory weights = new uint8[](n_influencers);
        address[] memory keys = new address[](n_influencers);
        if ((sig.length-21) % (65+msg_len) > 0) {
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        uint[] memory offsets = new uint[](n_influencers);

        return (influencers, keys, weights, offsets, msg_len);
    }

    function recoverSigParts(bytes sig, address last_address) private pure returns (address[], address[], uint8[], uint[]) {
        // sig structure:
        // 1 byte version 0 or 1
        // 20 bytes are the address of the contractor or the influencer who created sig.
        //  this is the "anchor" of the link
        //  It must have a public key aleady stored for it in public_link_key
        // Begining of a loop on steps in the link:
        // * 65 bytes are step-signature using the secret from previous step
        // * message of the step that is going to be hashed and used to compute the above step-signature.
        //   message length depend on version 41 (version 0) or 86 (version 1):
        //   * 1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut or weight for voting
        //   * 20 bytes address of influencer (version 0) or 65 bytes of signature of cut using the influencer address to sign
        //   * 20 bytes public key of the last secret
        // In the last step the message can be optional. If it is missing the message used is the address of the sender
        uint idx = 0;
        uint msg_len;
        uint8[] memory weights;
        address[] memory keys;
        address[] memory influencers;
        uint[] memory offsets;
        (influencers, keys, weights, offsets, msg_len) = recoverSigMemory(sig);
        idx += 1;  // skip version

        idx += 20; // skip old_address which should be read by the caller in order to get old_key
        uint count_influencers = 0;

        while (idx + 65 <= sig.length) {
            offsets[count_influencers] = idx;
            idx += 65;  // idx was increased by 65 for the signature at the begining which we will process later

            if (idx + msg_len <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                weights[count_influencers] = loadUint8(sig, idx);
                require(weights[count_influencers] > 0,'weight not defined (1..255)');  // 255 are used to indicate default (equal part) behaviour
                idx++;


                if (msg_len == 41)  // 1+20+20 version 0
                {
                    influencers[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                    keys[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                } else if (msg_len == 86)  // 1+65+20 version 1
                {
                    keys[count_influencers] = loadAddress(sig, idx+65);
                    influencers[count_influencers] = recoverHash(
                        keccak256(
                            abi.encodePacked(
                                keccak256(abi.encodePacked("bytes binding to weight","bytes binding to public")),
                                keccak256(abi.encodePacked(weights[count_influencers],keys[count_influencers]))
                            )
                        ),sig,idx);
                    idx += 65;
                    idx += 20;
                }

            } else {
                // handle short signatures generated with free_take
                influencers[count_influencers] = last_address;
            }
            count_influencers++;
        }
        require(idx == sig.length,'illegal message size');

        return (influencers, keys, weights, offsets);
    }

    function recoverSig(bytes sig, address old_key, address last_address) public pure returns (address[], address[], uint8[]) {
        // validate sig AND
        // recover the information from the signature: influencers, public_link_keys, weights/cuts
        // influencers may have one more address than the keys and weights arrays
        //
        require(old_key != address(0),'no public link key');

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        uint[] memory offsets;
        (influencers, keys, weights, offsets) = recoverSigParts(sig, last_address);

        // check if we received a valid signature
        for(uint i = 0; i < influencers.length; i++) {
            if (i < weights.length) {
                require (recoverHash(keccak256(abi.encodePacked(weights[i], keys[i], influencers[i])),sig,offsets[i]) == old_key, 'illegal signature');
                old_key = keys[i];
            } else {
                // signed message for the last step is the address of the converter
                require (recoverHash(keccak256(abi.encodePacked(influencers[i])),sig,offsets[i]) == old_key, 'illegal last signature');
            }
        }

        return (influencers, keys, weights);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

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

