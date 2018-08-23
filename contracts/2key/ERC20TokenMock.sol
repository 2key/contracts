pragma solidity ^0.4.24;


import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ERC20TokenMock is StandardToken {
	constructor() public {
		totalSupply_ = 1000000;
		balances[msg.sender] = totalSupply_;
	}

}
