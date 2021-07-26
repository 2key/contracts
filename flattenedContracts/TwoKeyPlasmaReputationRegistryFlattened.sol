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

contract ITwoKeyCPCCampaignPlasma {
    function getReferrers(
        address customer
    )
    public
    view
    returns (address[]);
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

contract ITwoKeyPlasmaFactory {
    function isCampaignCreatedThroughFactory(address _campaignAddress) public view returns (bool);
}

contract ITwoKeyPlasmaReputationRegistry {

    function updateReputationPointsForExecutedConversion(
        address converter,
        address contractor
    )
    public;

    function updateReputationPointsForRejectedConversions(
        address converter,
        address contractor
    )
    public;

    function updateUserReputationScoreOnSignup(
        address _plasmaAddress
    )
    public;
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

contract ITwoKeyPlasmaRegistryStorage is IStructuredStorage{

}

contract ITwoKeyPlasmaReputationRegistryStorage is IStructuredStorage {

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

contract TwoKeyPlasmaReputationRegistry is Upgradeable {
    /**
     * Contract to handle reputation points on plasma conversions for Budget campaigns
     * For all successful conversions initial reward is 1
     * For all rejected conversions initial penalty is 0.5
     */

    ITwoKeyPlasmaReputationRegistryStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;


    /**
     * Storage keys
     */
    string constant _plasmaAddress2contractorGlobalReputationScoreWei = "plasmaAddress2contractorGlobalReputationScoreWei";
    string constant _plasmaAddress2converterGlobalReputationScoreWei = "plasmaAddress2converterGlobalReputationScoreWei";
    string constant _plasmaAddress2referrerGlobalReputationScoreWei = "plasmaAddress2referrerGlobalReputationScoreWei";
    string constant _plasmaAddress2signupBonus = "plasmaAddress2signupBonus";

    string constant _plasmaAddress2Role2Feedback = "plasmaAddress2Role2Feedback";

    /**
     * @notice          Event which will be emitted every time reputation of a user
     *                  is getting changed. Either positive or negative.
     */
    event ReputationUpdated(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET,FEEDBACK)
        int _points,
        address _campaignAddress
    );

    event FeedbackSubmitted(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET)
        int _points,
        address _reporterPlasma,
        address _campaignAddress
    );

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
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaReputationRegistryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice          Modifier restricting access to the function only to campaigns
     *                  created using TwoKeyPlasmaFactory contract
     */
    modifier onlyBudgetCampaigns {
        require(
            ITwoKeyPlasmaFactory(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaFactory"))
            .isCampaignCreatedThroughFactory(msg.sender)
        );
        _;
    }

    /**
    * @notice          Modifier which will be used to restrict calls to only maintainers
    */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
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

    function isRoleExisting(
        string _role
    )
    internal
    pure
    returns (bool) {
        if(
            keccak256(_role) == keccak256("CONVERTER") ||
            keccak256(_role) == keccak256("REFERRER") ||
            keccak256(_role) == keccak256("CONTRACTOR")
        ) {
                return true;
        }
        return false;
    }

    /**
     * @notice          Internal wrapper function to fetch referrers for specific converter
     * @param           campaign is the address of the campaign
     * @param           converter is the address of converter for whom we want to fetch
     *                  the referrers
     */
    function getReferrers(
        address campaign,
        address converter
    )
    internal
    view
    returns (address[])
    {
        return ITwoKeyCPCCampaignPlasma(campaign).getReferrers(converter);
    }

    function addPositiveFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        string _type,
        int _pointsGained,
        address _reporterPlasma,
        address _campaignAddress
    )
    public
    onlyMaintainer
    {
        require(isRoleExisting(_role) == true);
        // generate key hash for current score
        bytes32 keyHashPlasmaAddressToFeedback = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, _role);
        // Load current score
        int currentScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedback);
        // Add to current score points gained
        PROXY_STORAGE_CONTRACT.setInt(keyHashPlasmaAddressToFeedback, currentScore + _pointsGained);

        emit FeedbackSubmitted(
            _plasmaAddress,
            _role,
            _type,
            _pointsGained,
            _reporterPlasma,
            _campaignAddress
        );
    }

    function addNegativeFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        string _type,
        int _pointsLost,
        address _reporterPlasma,
        address _campaignAddress
    )
    public
    onlyMaintainer
    {
        require(isRoleExisting(_role) == true);
        // generate key hash for current score
        bytes32 keyHashPlasmaAddressToFeedback = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, _role);
        // Load current score
        int currentScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedback);
        // Deduct from current score points lost
        PROXY_STORAGE_CONTRACT.setInt(keyHashPlasmaAddressToFeedback, currentScore - _pointsLost);

        emit FeedbackSubmitted(
            _plasmaAddress,
            _role,
            _type,
            _pointsLost*(-1),
            _reporterPlasma,
            _campaignAddress
        );
    }

    /**
     * @notice          Function to update reputation points for executed conversions
     *
     * @param           converter is the address who converted
     * @param           contractor is the address who created campaign
     */
    function updateReputationPointsForExecutedConversion(
        address converter,
        address contractor
    )
    public
    onlyBudgetCampaigns
    {
        int initialRewardWei = (10**18);

        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + initialRewardWei);

        emit ReputationUpdated(
            contractor,
            "CONTRACTOR",
            "BUDGET",
            initialRewardWei,
            msg.sender
        );

        updateConverterScore(converter, initialRewardWei);

        address[] memory referrers = getReferrers(msg.sender, converter);

        int j;

        for(int i=int(referrers.length)-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + reward);
            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "BUDGET",
                reward,
                msg.sender
            );
            j++;
        }

    }


    /**
     * @notice          Function to update reputation points for rejected conversions
     *
     * @param           converter is the address who converted
     * @param           contractor is the address who created campaign
     */
    function updateReputationPointsForRejectedConversions(
        address converter,
        address contractor
    )
    public
    onlyBudgetCampaigns
    {
        int initialPunishmentWei = (10**18) / 2;

        updateConverterScoreOnRejectedConversion(converter, initialPunishmentWei);

        address[] memory referrers = getReferrers(msg.sender, converter);

        int length = int(referrers.length);

        int j=0;
        for(int i=length-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialPunishmentWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "BUDGET",
                reward*(-1),
                msg.sender
            );
            j++;
        }

        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, contractor);

        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        int contractorPunishment = initialPunishmentWei/(length+1);

        PROXY_STORAGE_CONTRACT.setInt(
            keyHashContractorScore,
                contractorScore - contractorPunishment
        );

        emit ReputationUpdated(
            contractor,
            "CONTRACTOR",
            "BUDGET",
            contractorPunishment*(-1),
            msg.sender
        );
    }

    function updateConverterScoreOnRejectedConversion(
        address converter,
        int reward
    )
    internal
    {
        updateConverterScore(converter, reward*(-1));
    }

    function updateConverterScore(
        address converter,
        int reward
    )
    internal
    {
        bytes32 keyHashConverterScore = keccak256(_plasmaAddress2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + reward);

        emit ReputationUpdated(
            converter,
            "CONVERTER",
            "BUDGET",
            reward,
            msg.sender
        );
    }

    /**
     * @notice          Function to update user reputations score on signup action
     * @param           _plasmaAddress is user plasma address
     */
    function updateUserReputationScoreOnSignup(
        address _plasmaAddress
    )
    public
    {
        // Only TwoKeyPlasmaRegistry can call this method.
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry"));

        int signupReward = 5 * (10**18);

        bytes32 keyHash = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        // Require that this address haven't already got signup points allocated
        require(PROXY_STORAGE_CONTRACT.getInt(keyHash) == 0);

        // Allocate signup reward points for user.
        PROXY_STORAGE_CONTRACT.setInt(
            keyHash,
            signupReward
        );

        // Emit event
        emit ReputationUpdated(
            _plasmaAddress,
            "",
            "SIGNUP",
            signupReward,
            address(0)
        );
    }

    /**
     * @notice          Function to get reputation and feedback score in case he's an influencer & converter
     * @param           _plasmaAddress is plasma address of user
     */
    function getReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int,int,int,int,int)
    {
        int converterReputationScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2converterGlobalReputationScoreWei, _plasmaAddress)
        );

        int referrerReputationScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, _plasmaAddress)
        );

        int converterFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONVERTER")
        );

        int referrerFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "REFERRER")
        );

        return (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore,
            getUserSignupScore(_plasmaAddress)
        );
    }

    /**
     * @notice          Function to get global reputation for specific user
     * @param           _plasmaAddress is plasma address for user
     */
    function getGlobalReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int converterReputationScore;
        int referrerReputationScore;
        int converterFeedbackScore;
        int referrerFeedbackScore;
        int signupScore;

        (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore,
            signupScore
        ) = getReputationForUser(_plasmaAddress);

        return (converterReputationScore + referrerReputationScore + converterFeedbackScore + referrerFeedbackScore + signupScore);
    }


    /**
     * @notice          Function to get reputation and feedback score in
     *                  case he's a business page (contractor)
     * @param           _plasmaAddress is plasma address of user
     */
    function getReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int,int,int)
    {
        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, _plasmaAddress);
        int contractorReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        bytes32 keyHashPlasmaAddressToFeedbackAsContractor = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONTRACTOR");
        int contractorFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedbackAsContractor);

        bytes32 keyHashPlasmaAddressToSignupScore = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        int contractorSignupScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToSignupScore);

        return (
            contractorReputationScore,
            contractorFeedbackScore,
            contractorSignupScore
        );
    }

    /**
     * @notice          Function to get global reputation for contractor (business)
     */
    function getGlobalReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int contractorReputationScore;
        int contractorFeedbackScore;
        int contractorSignupScore;

        (contractorReputationScore,contractorFeedbackScore,contractorSignupScore) =
            getReputationForContractor(_plasmaAddress);

        return (contractorReputationScore + contractorFeedbackScore + contractorSignupScore);
    }


    /**
     * @notice          Function to return global reputation for requested users
     * @param           addresses is an array of plasma addresses of users
     */
    function getGlobalReputationForUsers(
        address [] addresses
    )
    public
    view
    returns (int[]) {
        uint len = addresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForUser(addresses[i]);
        }

        return (reputations);
    }

    /**
     * @notice          Function to get global reputations for contractors
     * @param           addresses is an array of plasma addresses of contractors (businesses)
     */
    function getGlobalReputationForContractors(
        address [] addresses
    )
    public
    view
    returns (int[])
    {
        uint len = addresses.length;

        int [] memory reputations = new int[](len);

        uint i;
        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForContractor(addresses[i]);
        }

        return (reputations);
    }

    /**
     * @notice          Function to check user signup score
     * @param           _plasmaAddress is user plasma address
     * @return          reputation points user earned for signup action.
     */
    function getUserSignupScore(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        bytes32 keyHashPlasmaAddressToSignupScore = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        int signupScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToSignupScore);
        return signupScore;
    }
}

