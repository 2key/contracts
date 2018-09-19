pragma solidity ^0.4.24;


import '../openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract ERC20TokenMock is StandardToken {
	constructor() public {
		tokenSymbol = "TKN";
		decimals = 10;
		totalSupply_ = 1000000;
		balances[msg.sender] = totalSupply_;
	}

	function getDecimals() public view returns (uint) {
		return decimals;
	}

	function getTokenSymbol() public view returns (string) {
		return tokenSymbol;
	}

}
