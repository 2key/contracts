pragma solidity ^0.4.24;

import '../libraries/Call.sol';
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaEventsStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";

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
