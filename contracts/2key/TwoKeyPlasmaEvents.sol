pragma solidity ^0.4.24; //We have to specify what version of compiler this code will use
import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TwoKeyPlasmaEvents is Ownable {


    mapping(address => mapping(address => mapping(address => bool))) public visits;
    mapping(address => bool) public verifiedUsers;

    // Its better if dApp handles created contract by itself
    //  mapping(address => address) public verifiedCampaigns;
    //  function verifiedContract(address owner, address c) onlyOwner public {
    //    verifiedCampaigns[c] = owner;
    //  }

    function verifiedUser(address owner) onlyOwner public {
        verifiedUsers[owner] = true;
    }

    event Visited(address indexed to, address indexed c, address from);
    event Joined(address indexed _campaign, address indexed _from, address indexed _to);

    function visited(address from, address c) public {
        // Its better if dApp handles created contract by itself
        //    require(verifiedCampaigns[c] != address(0));
        address to = msg.sender;
        require(verifiedUsers[to]);
        if (!visits[c][from][to]) {  // generate event only once for each tripplet
            visits[c][from][to] = true;
            emit Visited(to, c, from);
        }
    }

    /// @notice Function which will emit event joined
    /// @dev just need probably to add some logic inside method (?)- status call discussion
    /// @dev is _from actually msg.sender?
    function joined(address _campaign, address _from, address _to) public {
        emit Joined(_campaign, _from, _to);
    }
}