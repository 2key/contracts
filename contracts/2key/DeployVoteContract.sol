pragma solidity ^0.4.24;

import "./TwoKeyWeightedVoteContract.sol";

contract DeployVoteContract {
    function deployTwoKeyWeightedContract() public returns (address) {
        address voteContract = new TwoKeyWeightedVoteContract();
        return voteContract;
    }
}
