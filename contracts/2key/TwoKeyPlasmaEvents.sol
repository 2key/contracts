pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use
import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TwoKeyPlasmaEvents is Ownable {
    // TODO make sure the owner is really using a secret private key


    mapping(address => mapping(address => mapping(address => bool))) public visits;
    mapping(address => mapping(address => address[])) public visits_list;
    mapping(address => bool) public verifiedUsers;
    mapping(address => address) public plasma2ethereum;

    // Its better if dApp handles created contract by itself
    //  mapping(address => address) public verifiedCampaigns;
    //  function verifiedContract(address owner, address c) onlyOwner public {
    //    verifiedCampaigns[c] = owner;
    //  }

    function verifiedUser(address owner) onlyOwner public {
        verifiedUsers[owner] = true;
    }

    event Visited(address indexed to, address indexed c, address from);  // the to is a plasma address, you should look it up in plasma2ethereum
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);

    function toString(address x) public pure returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    function add_plasma2ethereum(bytes sig) public {
        // Its better if dApp handles created contract by itself
        //    require(verifiedCampaigns[c] != address(0));
//        bytes32 hash = keccak256(abi.encodePacked(toString(msg.sender)));
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

    function visited(address from, address c) public {
        address to = msg.sender;
        //    require(verifiedUsers[to]);  // TODO we want to use verified users BUT without gas
        if (!visits[c][from][to]) {  // generate event only once for each tripplet
            visits[c][from][to] = true;
            visits_list[c][from].push(to);
            emit Visited(to, c, from);
        }
    }

    /// @notice Function which will emit event joined
    /// @dev just need probably to add some logic inside method (?)- status call discussion
    /// @dev is _from actually msg.sender?
    function joined(address _campaign, address _from, address _to) public {
        // TODO replace to with sig?
        //    require(verifiedUsers[to]);  // TODO we want to use verified users BUT without gas
        emit Joined(_campaign, _from, _to);
    }

    // return a list of plasma address
    function get_visits_list(address from, address c) public view returns (address[]) {
        return visits_list[c][from];
    }
}