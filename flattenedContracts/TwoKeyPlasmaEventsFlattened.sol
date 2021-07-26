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

contract ITwoKeyPlasmaEventsStorage is IStructuredStorage{

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

contract TwoKeyPlasmaEvents is Upgradeable {

    ITwoKeyPlasmaEventsStorage public PROXY_STORAGE_CONTRACT;

    string constant _publicLinkKey = "public_link_key";
    string constant _influencer2cut = "influencer2cut";
    string constant _notes = "notes";
    string constant _campaign2numberOfJoins = "campaign2numberOfJoins";
    string constant _campaign2numberOfForwarders = "campaign2numberOfForwarders";
    string constant _campaign2numberOfVisits = "campaign2numberOfVisits";
    string constant _campaignToReferrerToCounted = "campaignToReferrerToCounted";
    string constant _visits = "visits";
    string constant _visited_from_time = "visited_from_time";
    string constant _visited_sig = "visited_sig";
    string constant _visited_from = "visited_from";
    string constant _joined_from = "joined_from";
    string constant _visits_list = "visits_list";
    string constant _visits_list_timestamps = "visits_list_timestamps";


    string constant _twoKeyPlasmaRegistry = "TwoKeyPlasmaRegistry";
    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";



    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    bool initialized;

    event Visited(
        address indexed to,
        address indexed c,
        address indexed contractor,
        address from
    );  // the to is a plasma address, you should lookit up in plasma2ethereum


    event Joined(
        address campaignAddress,
        address fromPlasma,
        address toPlasma
    );


    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaEventsStorage(_proxyStorage);
        //Adding initial maintainers
        initialized = true;
    }


    // Internal function to fetch address from TwoKeyRegTwoistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }



    function plasmaOf(address me) internal view returns (address) {
        address twoKeyPlasmaEventsRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaRegistry);
        address plasma = ITwoKeyPlasmaRegistry(twoKeyPlasmaEventsRegistry).ethereum2plasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }



    function ethereumOf(address me) internal view returns (address) {
        address twoKeyPlasmaEventsRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaRegistry);
        address ethereum = ITwoKeyPlasmaRegistry(twoKeyPlasmaEventsRegistry).plasma2ethereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }



    function setPublicLinkKeyOf(address c, address contractor, address new_address, address new_public_key) private {
        new_address = plasmaOf(new_address);

        bytes32 keyHashPublicLinkKey = keccak256(_publicLinkKey,c,contractor,new_address);
        address old_address = PROXY_STORAGE_CONTRACT.getAddress(keyHashPublicLinkKey);
        if (old_address == address(0)) {
            PROXY_STORAGE_CONTRACT.setAddress(keyHashPublicLinkKey, new_public_key);
        } else {
            require(old_address == new_public_key);
        }
    }



    function setPublicLinkKey(address c, address contractor, address new_public_key) public {
        setPublicLinkKeyOf(c, contractor, msg.sender, new_public_key);
    }



    function setCutOf(address c, address contractor, address me, uint256 cut) internal {
        // what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        address plasma = plasmaOf(me);
        bytes32 keyHashInfluencerToCut = keccak256(_influencer2cut, c, contractor, plasma);
        uint cutSaved = PROXY_STORAGE_CONTRACT.getUint(keyHashInfluencerToCut);
        require(cutSaved == 0 || cutSaved == cut);
        PROXY_STORAGE_CONTRACT.setUint(keyHashInfluencerToCut, cut);
    }



    function setCut(address c, address contractor, uint256 cut) public {
        setCutOf(c, contractor, msg.sender, cut);
    }



    function cutOf(address c, address contractor, address me) public view returns (uint256) {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_influencer2cut, c, contractor, plasmaOf(me)));
    }



    function test_path(address c, address contractor, address to) private view returns (bool) {
        contractor = plasmaOf(contractor);
        to = plasmaOf(to);
        while(to != contractor) {
            if(to == address(0)) {
                return false;
            }
            to = plasmaOf(getVisitedFrom(c, contractor, to));
        }
        return true;
    }



    function publicLinkKeyOf(address c, address contractor, address me) public view returns (address) {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_publicLinkKey,c,contractor,plasmaOf(me)));
    }



    function setNoteByUser(address c, bytes note) public {
        PROXY_STORAGE_CONTRACT.setBytes(keccak256(_notes,c,msg.sender), note);
    }



    function notes(address c, address _plasma) public view returns (bytes) {
        return PROXY_STORAGE_CONTRACT.getBytes(keccak256(_notes,c, _plasma));
    }



    function joinCampaign(address campaignAddress, address contractor, bytes sig) public {
        address old_address;
        assembly
        {
            old_address := mload(add(sig, 21))
        }
        old_address = plasmaOf(old_address);
        // validate an existing visit path from contractor address to the old_address
        require(test_path(campaignAddress, contractor, old_address));
        address old_key = publicLinkKeyOf(campaignAddress, contractor, old_address);
        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address last_address = msg.sender;
        (influencers, keys, weights) = Call.recoverSig(sig, old_key, last_address);

        // Limit referral chain for campaigns to 40 influencers
        require(influencers.length <= 40);

        address referrer = contractor;
        require(influencers[influencers.length-1] == last_address);
        if (influencers.length > 1) {
            referrer = influencers[influencers.length - 2];
        }
        bytes32 keyJoins = keccak256(_campaign2numberOfJoins, campaignAddress);
        PROXY_STORAGE_CONTRACT.setUint(keyJoins, PROXY_STORAGE_CONTRACT.getUint(keyJoins) + 1);

        setJoinedFrom(campaignAddress, contractor, last_address, referrer);
        setVisitedFrom(campaignAddress, contractor, last_address, referrer);
        emit Joined(campaignAddress, plasmaOf(referrer), last_address);
    }



    function visited(address c, address contractor, bytes sig) public {
        // c - addresss of the contract on ethereum
        // contractor - is the ethereum address of the contractor who created c. a dApp can read this information for free from ethereum.
        address old_address;
        assembly
        {
            old_address := mload(add(sig, 21))
        }
        old_address = plasmaOf(old_address);

        // validate an existing visit path from contractor address to the old_address
        require(test_path(c, contractor, old_address));

        address old_key = publicLinkKeyOf(c, contractor, old_address);


        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address last_address = msg.sender;
        (influencers, keys, weights) = Call.recoverSig(sig, old_key, last_address);

        // Limit referral chain for campaigns to 40 influencers
        require(influencers.length <= 40);

        require(influencers[influencers.length-1] == last_address);
        setVisitedSig(c, contractor, last_address, sig);

        if(influencers.length > 1 && getCampaignToReferrerToCounted(c,influencers[influencers.length-2]) == false && influencers[influencers.length-2] != contractor) {
            setCampaignToReferrerToCounted(c, influencers[influencers.length-2]);
            bytes32 key = keccak256(_campaign2numberOfForwarders,c);
            PROXY_STORAGE_CONTRACT.setUint(key, PROXY_STORAGE_CONTRACT.getUint(key) + 1);
        }

        uint i;
        address new_address;
        // move ARCs based on signature information
        for (i = 0; i < influencers.length; i++) {
            new_address = influencers[i];
            require(new_address != plasmaOf(contractor));
            if (!getVisits(c,contractor,old_address,new_address)) {  // generate event only once for each tripplet
                setVisits(c,contractor,old_address,new_address);
                incrementNumberOfVisitsPerCampaign(c);

                if (getJoinedFrom(c, contractor, new_address) == address(0)) {
                    setVisitedFrom(c, contractor, new_address, old_address);
                }
                emit Visited(new_address, c, contractor, old_address);
            }
            old_address = new_address;
        }

        for (i = 0; i < keys.length; i++) {
            setPublicLinkKeyOf(c, contractor, influencers[i], keys[i]);
        }

        for (i = 0; i < weights.length; i++) {
            setCutOf(c, contractor, influencers[i], weights[i]);
        }

    }



    function visitsListEx(address c, address contractor, address from) public view returns (address[], uint[]) {
        from = plasmaOf(from);
        return (getVisitsList(c, contractor, from), getVisitsListTimestamps(c, contractor, from));
    }



    function getNumberOfVisitsAndJoinsAndForwarders(
        address campaignAddress
    )
    public
    view
    returns (uint,uint,uint)
    {
        return (
            PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaign2numberOfVisits,campaignAddress)),
            PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaign2numberOfJoins,campaignAddress)),
            PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaign2numberOfForwarders, campaignAddress))
        );
    }



    function getCampaignToReferrerToCounted(address campaign, address influencer) internal view returns (bool) {
        return PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignToReferrerToCounted, campaign, influencer));
    }



    function setCampaignToReferrerToCounted(address campaign, address influencer) internal {
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignToReferrerToCounted, campaign, influencer), true);
    }



    function getVisits(address campaign, address contractor, address old_address, address new_address) internal view returns (bool) {
        return PROXY_STORAGE_CONTRACT.getBool(keccak256(_visits,campaign,contractor,old_address,new_address));
    }



    function setVisits(address campaign, address contractor, address old_address, address new_address) internal {
        return PROXY_STORAGE_CONTRACT.setBool(keccak256(_visits,campaign,contractor,old_address,new_address), true);
    }



    function incrementNumberOfVisitsPerCampaign(address campaign) internal {
        bytes32 key = keccak256(_campaign2numberOfVisits,campaign);
        PROXY_STORAGE_CONTRACT.setUint(key, PROXY_STORAGE_CONTRACT.getUint(key) + 1);
    }



    function setVisitedFromTime(address campaign, address contractor, address new_address, address old_address) internal {
        bytes32 keyHash = keccak256(_visited_from_time, campaign, contractor, new_address, old_address);
        PROXY_STORAGE_CONTRACT.setUint(keyHash, block.timestamp);
    }



    function setVisitedSig(address _campaign, address _contractor, address _last_address, bytes _sig) internal {
        bytes32 keyHash = keccak256(_visited_sig, _campaign, _contractor, _last_address);
        PROXY_STORAGE_CONTRACT.setBytes(keyHash, _sig);
    }



    function getVisitedFrom(address c, address contractor, address _address) public view returns (address) {
        bytes32 keyHash = keccak256(_visited_from, c, contractor, _address);
        return ethereumOf(PROXY_STORAGE_CONTRACT.getAddress(keyHash));
    }



    function setVisitedFrom(address c, address contractor, address _oldAddress, address _newAddress) internal {
        bytes32 keyHash = keccak256(_visited_from, c, contractor, _oldAddress);
        PROXY_STORAGE_CONTRACT.setAddress(keyHash, _newAddress);
    }



    function setJoinedFrom(address _c, address _contractor, address _old_address, address _new_address) internal {
        bytes32 keyHash = keccak256(_joined_from, _c, _contractor, _old_address);
        PROXY_STORAGE_CONTRACT.setAddress(keyHash, _new_address);
    }



    function getJoinedFrom(address _c, address _contractor, address _address) public view returns (address) {
        bytes32 keyHash = keccak256(_joined_from, _c, _contractor, _address);
        return plasmaOf(PROXY_STORAGE_CONTRACT.getAddress(keyHash));
    }



    function getVisitsList(address _c, address _contractor, address _referrer) internal view returns (address[]) {
        bytes32 keyHash = keccak256(_visits_list, _c, _contractor, _referrer);
        return PROXY_STORAGE_CONTRACT.getAddressArray(keyHash);
    }



    function setVisitsList(address _c, address _contractor, address _referrer, address _visitor) internal {
        address[] memory visitsList = getVisitsList(_c, _contractor, _referrer);
        address[] memory newVisitsList = new address[](visitsList.length + 1);
        for(uint i=0; i< visitsList.length; i++) {
            newVisitsList[i] = visitsList[i];
        }
        newVisitsList[visitsList.length] = _visitor;

        bytes32 keyHash = keccak256(_visits_list, _c, _contractor, _referrer);
        PROXY_STORAGE_CONTRACT.setAddressArray(keyHash, newVisitsList);
    }



    function getVisitsListTimestamps(address _c, address _contractor, address _referrer) public view returns (uint[]) {
        bytes32 keyHash = keccak256(_visits_list_timestamps, _c, _contractor, _referrer);
        return PROXY_STORAGE_CONTRACT.getUintArray(keyHash);
    }



    function setVisitsListTimestamps(address _c, address _contractor, address _referrer) internal {
        uint[] memory visitListTimestamps = getVisitsListTimestamps(_c, _contractor, _referrer);
        uint[] memory newVisitListTimestamps = new uint[](visitListTimestamps.length + 1);
        for(uint i=0; i< visitListTimestamps.length; i++) {
            newVisitListTimestamps[i] = visitListTimestamps[i];
        }
        newVisitListTimestamps[visitListTimestamps.length] = block.timestamp;

        bytes32 keyHash = keccak256(_visits_list_timestamps, _c, _contractor, _referrer);
        PROXY_STORAGE_CONTRACT.setUintArray(keyHash, newVisitListTimestamps);
    }





}

