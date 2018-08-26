pragma solidity ^0.4.24;

import "../openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ITwoKeyWhitelisted is Ownable{
    function isWhitelisted(address _beneficiary) public view returns(bool);
    function addToWhitelist(address _beneficiary) public onlyOwner;
    function addManyToWhitelist(address[] _beneficiaries) public onlyOwner;
    function removeFromWhitelist(address _beneficiary) public onlyOwner;
}
