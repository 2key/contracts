pragma solidity ^0.4.24;

contract ITwoKeyWeightedVoteContract {
    function getDescription() public view returns(string);
    function transferSig(bytes sig) public returns (address[]);
    function setValid() public;
}
