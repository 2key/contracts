pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use
import './Call.sol';
import "./Upgradeable.sol";

contract TwoKeyPlasmaEvents is Upgradeable {

    address public owner;
    bool initialized = false;
    // every event we generate contains both the campaign address and the address of the contractor of that campaign
    // both are ethereum address.
    // this plasma contract does not know in itself who is the contractor on the ethereum network
    // instead it receives the contractor address when a method is called and then emits an event with that address
    // a different user can use a dApp that access both ethereum and plasma networks. The dApp first read the correct contractor address from etherum
    // and then the dApp filter only plasma events that contain the correct contractor address. Filtering out any false events that may be generated by
    // a malicous plasma user.
    event Visited(address indexed to, address indexed c, address indexed contractor, address from);  // the to is a plasma address, you should look it up in plasma2ethereum
    event Plasma2Ethereum(address plasma, address eth);

    // campaign,contractor eth-addr=>user eth-addr=>public key
    // we keep the contractor address for each campaign contract because we dont have access to the ethereum network
    // from inside plama network and we can not read who is the contractor of the campaign.
    // instead we relly on the plasma user to supply this information for us
    // and later we will generate a Visited event that will contain this information.
    mapping(address => mapping(address => mapping(address => address))) public public_link_key;
    // campaign,contractor eth-addr=>user eth-addr=>cut
    // The cut from the bounty each influencer is taking + 1
    // zero (also the default value) indicates default behaviour in which the influencer takes an equal amount as other influencers
    mapping(address => mapping(address => mapping(address => uint256))) public influencer2cut;
    // plasma address => ethereum address
    // note that more than one plasma address can point to the same ethereum address so it is not critical to use the same plasma address all the time for the same user
    // in some cases the plasma address will be the same as the ethereum address and in that case it is not necessary to have an entry
    // the way to know if an address is a plasma address is to look it up in this mapping
    mapping(address => address) public plasma2ethereum;
    mapping(address => address) public ethereum2plasma;

    // campaign,contractor eth-addr=>from eth-addr=>to eth or plasma address=>true/false
    // not that the "to" addrss in an edge of the graph can be either a plasma or an ethereum address
    // the from address is always an ethereum address
    mapping(address => mapping(address => mapping(address => mapping(address => bool)))) public visits;
    // campaign,contractor eth-addr=>to eth or plasma-addr=>from eth-addr=>true/false
    mapping(address => mapping(address => mapping(address => address))) public visited_from;
    // campaign,contractor eth-addr=>from eth-addr=>list of to eth or plasma address.
    mapping(address => mapping(address => mapping(address => address[]))) public visits_list;

    mapping(address => mapping(address => mapping(address => bytes))) public visited_sig;
    mapping(address => mapping(address => bytes)) public notes;

    mapping(address => mapping(address => uint256)) public voted_yes;
    mapping(address => mapping(address => uint256)) public weighted_yes;
    mapping(address => mapping(address => uint256)) public voted_no;
    mapping(address => mapping(address => uint256)) public weighted_no;

    mapping(address => bool) public isMaintainer;

    function setInitialParams(address[] maintainers) public {
        require(initialized == false);
        initialized = true;
        owner = msg.sender;
        //Adding initial maintainers
        for(uint i=0; i<maintainers.length; i++) {
            isMaintainer[maintainers[i]] = true;
        }
    }

    function add_plasma2ethereum(address plasma_address, bytes sig) public { // , bool with_prefix) public {
//        address plasma_address = msg.sender;
        // add an entry connecting msg.sender to the ethereum address that was used to sign sig.
        // see setup_demo.js on how to generate sig
//        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(msg.sender))));
        //TODO Nikola add next line logic
        require(msg.sender == plasma_address || isMaintainer[msg.sender]);
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(plasma_address))));
        require (sig.length == 65, 'bad plasma signature length');
        address eth_address = Call.recoverHash(hash,sig,0);
        require(plasma2ethereum[plasma_address] == address(0) || plasma2ethereum[plasma_address] == eth_address, "cant change plasma=>eth");
        plasma2ethereum[plasma_address] = eth_address;
        ethereum2plasma[eth_address] = plasma_address;

        emit Plasma2Ethereum(plasma_address, eth_address);
    }



    function plasmaOf(address me) public view returns (address) {
        address plasma = ethereum2plasma[me];
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    function ethereumOf(address me) public view returns (address) {
        address ethereum = plasma2ethereum[me];
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    function setPublicLinkKeyOf(address c, address contractor, address new_address, address new_public_key) private {
        // TODO keep same as code in TwoKeySignedContract.sol:transferSig
        // update (only once) the public address used by each influencer
        // we will need this in case one of the influencers will want to start his own off-chain link
        new_address = plasmaOf(new_address);
        address old_address = public_link_key[c][contractor][new_address];
        if (old_address == address(0)) {
            public_link_key[c][contractor][new_address] = new_public_key;
        } else {
            require(old_address == new_public_key,'public key can not be modified');
        }
    }
    // have a different setPublicLinkKey method that a plasma user can call with a new contract,public_link_key
    // The steps are as follow:
    // 1. make sure you have an ethereum address
    // 2. call add_plasma2ethereum to make a connection between plamsa address (msg.sender) to ethereum address
    // 3. the plasma user pass his ethereum address with the public key used in 2key-link
    //
    function setPublicLinkKey(address c, address contractor, address new_public_key) public {
        setPublicLinkKeyOf(c, contractor, msg.sender, new_public_key);
    }

    function setCutOf(address c, address contractor, address me, uint256 cut) internal {
        // what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        address plasma = plasmaOf(me);
        require(influencer2cut[c][contractor][plasma] == 0 || influencer2cut[c][contractor][plasma] == cut, 'cut already set differently');
        if (influencer2cut[c][contractor][plasma] == 0) {
            if (0 < cut && cut <= 101) {
                voted_yes[c][contractor]++;
                weighted_yes[c][contractor] += cut-1;
            } else if (154 < cut && cut < 255) {
                voted_no[c][contractor]++;
                weighted_no[c][contractor] += 255-cut;
            }
        }
        influencer2cut[c][contractor][plasma] = cut;
    }

    function setCut(address c, address contractor, uint256 cut) public {
        setCutOf(c, contractor, msg.sender, cut);
    }

    function cutOf(address c, address contractor, address me) public view returns (uint256) {
        return influencer2cut[c][contractor][plasmaOf(me)];
    }

    function test_path(address c, address contractor, address to) private view returns (bool) {
        contractor = plasmaOf(contractor);
        to = plasmaOf(to);
        while(to != contractor) {
            if(to == address(0)) {
                return false;
            }
            to = visited_from[c][contractor][to];
        }
        return true;
    }

    function publicLinkKeyOf(address c, address contractor, address me) public view returns (address) {
        return public_link_key[c][contractor][plasmaOf(me)];
    }

    function setNoteByUser(address c, bytes note) public {
        // note is a message you can store with sig. For example it could be the secret you used encrypted by you
        notes[c][msg.sender] = note;
    }

    function visited(address c, address contractor, bytes sig) public {
        // c - addresss of the contract on ethereum
        // contractor - is the ethereum address of the contractor who created c. a dApp can read this information for free from ethereum.
        // caller must use the 2key-link and put his plasma address at the end using free_take
        // sig contains the "from" and at the end of sig you should put your own plasma address (msg.sender) or a signature of cut using it

        address old_address;
        assembly
        {
            old_address := mload(add(sig, 21))
        }
        old_address = plasmaOf(old_address);
        // validate an existing visit path from contractor address to the old_address
        require(test_path(c, contractor, old_address), 'no path to contractor');

        address old_key = publicLinkKeyOf(c, contractor, old_address);


        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address last_address = msg.sender;
        (influencers, keys, weights) = Call.recoverSig(sig, old_key, last_address);
        // check if we exactly reached the end of the signature. this can only happen if the signature
        // was generated with free_join_take and in this case the last part of the signature must have been
        // generated by the caller of this method
        require(influencers[influencers.length-1] == last_address, 'only the last in the link can call visited');
        visited_sig[c][contractor][last_address] = sig;

        uint i;
        address new_address;
        // move ARCs based on signature information
        for (i = 0; i < influencers.length; i++) {
            new_address = influencers[i];
            require(new_address != plasmaOf(contractor), 'contractor can not be an influencer');
            // NOTE!!!! for the last user in the sig the  new_address can be a plasma_address
            // as a result the same user with a plasma_address can appear later with an etherum address
            if (!visits[c][contractor][old_address][new_address]) {  // generate event only once for each tripplet
                visits[c][contractor][old_address][new_address] = true;
                visited_from[c][contractor][new_address] = old_address;
                visits_list[c][contractor][old_address].push(new_address);
                emit Visited(new_address, c, contractor, old_address);
            } else {
                require(visited_from[c][contractor][new_address] == old_address, 'User already visited from a different influencer');
            }

            old_address = new_address;
        }

        for (i = 0; i < keys.length; i++) {
            // TODO Updating the public key of influencers may not a good idea because it will require the influencers to use
            // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
            // TODO a possible solution is change public_link_key to address=>address[]
            // update (only once) the public address used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            setPublicLinkKeyOf(c, contractor, influencers[i], keys[i]);
        }

        for (i = 0; i < weights.length; i++) {
            setCutOf(c, contractor, influencers[i], weights[i]);
        }
    }

    function visitsList(address c, address contractor, address from) public view returns (address[]) {
        from = plasmaOf(from);
        return visits_list[c][contractor][from];
    }

    function votes(address c, address contractor) public view returns (uint256, uint256, uint256, uint256, uint256, int) {
        return (
        voted_yes[c][contractor], weighted_yes[c][contractor], voted_no[c][contractor], weighted_no[c][contractor],
        voted_yes[c][contractor] + voted_no[c][contractor], int(weighted_yes[c][contractor]) - int(weighted_no[c][contractor])
        );
    }

    /**
     * @notice Function which can add new maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only owner contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function addMaintainers(address [] _maintainers) public {
        require(msg.sender == owner);
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only owner contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(address [] _maintainers) public {
        require(msg.sender == owner);
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }
}