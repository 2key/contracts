pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use
import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TwoKeyPlasmaEvents is Ownable {

    // REPLICATE INFO FROM REAL NETWORK
    // the backend "inspector" process listen to events in the real network and write them here
    // TODO make sure the owner is really using a secret private key
    mapping(address => bool) public verifiedUsers;
    mapping(address => mapping(address => address))  public public_link_key;
    // The cut from the bounty each influencer is taking + 1
    // zero (also the default value) indicates default behaviour in which the influencer takes an equal amount as other influencers
    mapping(address => mapping(address => uint256)) public influencer2cut;
    function setPublicLinkKey(address c, address owner, address _public_link_key) onlyOwner public {
        //  this method is called by the inspector backend process everytime it sees an event that
        // setPublicLinkKey was called on a campaign contract
        // NOTE c, owner is the address on the real network, not on plasma
        public_link_key[c][owner] = _public_link_key;
    }
    function verifiedUser(address owner) onlyOwner public {
        //  this method is called by the inspector backend process everytime it sees an event UserNameChanged coming
        // from TwoKeyReg contract in the real network
        // NOTE owner is the address on the real network, not on plasma
        verifiedUsers[owner] = true;
    }

    ///

    mapping(address => mapping(address => mapping(address => bool))) public visits;
    mapping(address => mapping(address => address[])) public visits_list;
    mapping(address => address) public plasma2ethereum;
//    mapping(address => bytes[]) public sign_list;

    // Its better if dApp handles created contract by itself
    //  mapping(address => address) public verifiedCampaigns;
    //  function verifiedContract(address owner, address c) onlyOwner public {
    //    verifiedCampaigns[c] = owner;
    //  }


    event Visited(address indexed to, address indexed c, address from);  // the to is a plasma address, you should look it up in plasma2ethereum
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);


    function add_plasma2ethereum(bytes sig) public {
        // Its better if dApp handles created contract by itself
        //    require(verifiedCampaigns[c] != address(0));
        bytes32 hash = keccak256(keccak256(abi.encodePacked("bytes binding to plasma address")),keccak256(abi.encodePacked(msg.sender)));
        require (sig.length == 65, 'bad signature length');
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        uint idx = 32;
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

        address eth_address = ecrecover(hash, v, r, s);
        plasma2ethereum[msg.sender] = eth_address;
    }

    function visited(address c, bytes sig) public {
        // caller must use the 2key-link and put his plasma address at the end using free_take
        // sig contains the "from" and at the tip of sig you should put your own plasma address (msg.sender)

        // TODO keep table of all 2keylinks of all contracts

        // code bellow should be kept identical to transferSig when using free_take
        uint idx = 0;

        address old_address;
        if (idx+20 <= sig.length) {
            idx += 20;
            assembly
            {
                old_address := mload(add(sig, idx))
            }
        }

        address old_public_link_key = public_link_key[c][old_address];
        require(old_public_link_key != address(0),'no public link key');

        while (idx + 65 <= sig.length) {
            // The signature format is a compact form of:
            //   {bytes32 r}{bytes32 s}{uint8 v}
            // Compact means, uint8 is not padded to 32 bytes.
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

            // idx was increased by 65

            bytes32 hash;
            address new_public_key;
            address new_address;
            if (idx + 41 <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                uint8 bounty_cut;
                {
                    idx += 1;
                    assembly
                    {
                        bounty_cut := mload(add(sig, idx))
                    }
                    require(bounty_cut > 0,'bounty/weight not defined (1..255)');
                }

                idx += 20;
                assembly
                {
                    new_address := mload(add(sig, idx))
                }

                idx += 20;
                assembly
                {
                    new_public_key := mload(add(sig, idx))
                }

                // update (only once) the cut used by each influencer
                // we will need this in case one of the influencers will want to start his own off-chain link
                if (influencer2cut[c][new_address] == 0) {
                    influencer2cut[c][new_address] = uint256(bounty_cut);
                } else {
                    require(influencer2cut[c][new_address] == uint256(bounty_cut),'bounty cut can not be modified');
                }

                // update (only once) the public address used by each influencer
                // we will need this in case one of the influencers will want to start his own off-chain link
                if (public_link_key[c][new_address] == 0) {
                    public_link_key[c][new_address] = new_public_key;
                } else {
                    require(public_link_key[c][new_address] == new_public_key,'public key can not be modified');
                }

                hash = keccak256(abi.encodePacked(bounty_cut, new_public_key, new_address));

                // check if we exactly reached the end of the signature. this can only happen if the signature
                // was generated with free_take_join and in this case the last part of the signature must have been
                // generated by the caller of this method
                if (idx == sig.length) {  // TODO this does not makes sense when done on plasma because the new_address is a plasma address and all previous address were real
                    require(new_address == msg.sender,'only the last in the link can call transferSig');
                }
            } else {
                // handle short signatures generated with free_take
                // signed message for the last step is the address of the converter
                new_address = msg.sender;
                hash = keccak256(abi.encodePacked(new_address));
            }

            if (!visits[c][old_address][new_address]) {  // generate event only once for each tripplet
                visits[c][old_address][new_address] = true;
                visits_list[c][old_address].push(new_address);
                emit Visited(new_address, c, old_address);
            }

            // check if we received a valid signature
            address signer = ecrecover(hash, v, r, s);
            require (signer == old_public_link_key, 'illegal signature');
            old_public_link_key = new_public_key;
            old_address = new_address;
        }
        require(idx == sig.length,'illegal message size');
    }

    /// @notice Function which will emit event joined
    /// @dev just need probably to add some logic inside method (?)- status call discussion
    /// @dev is _from actually msg.sender?
    function joined(address _campaign, address _from, address _to) public {
        // TODO replace to with sig?
        //    require(verifiedUsers[to]);  // TODO we want to use verified users BUT without gas. if using sign then we dont have to
        // TODO do we want to enforce visited first
        // TODO _to should be msg.sender
        emit Joined(_campaign, _from, _to);
    }

    // return a list of plasma address
    function get_visits_list(address from, address c) public view returns (address[]) {
        return visits_list[c][from];
    }

    // TODO similar method of get_visits_list for joins

}