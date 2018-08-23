pragma solidity ^0.4.24;

contract BasicStorage {

    uint256 storedData;

    event Store(address a, uint256 _d);

    constructor() public payable {

    }

	function set(uint256 x) public payable {
        storedData = x;
        emit Store(address(this), x);
    }
    
	function get() view public returns (uint256) {
        return storedData;
    }

    function() public payable {

    }
}