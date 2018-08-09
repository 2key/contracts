pragma solidity ^0.4.24;

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';


contract CrowdsaleWithTwoKey is WhitelistedCrowdsale {

	constructor(uint256 _rate, address _wallet, ERC20 _token) Crowdsale(_rate, _wallet, _token) public {
	}

	// to be overriden per bonus
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
	    // give bonuses
	}
}