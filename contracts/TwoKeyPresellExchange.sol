pragma solidity ^0.4.24;

import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol';
import './TwoKeyUpgradableExchange.sol';


contract TwoKeyPresellExchange is WhitelistedCrowdsale, TimedCrowdsale, CappedCrowdsale, TwoKeyUpgradableExchange {
	// bonus precentage
	// time locked base to some time after presell
	// after release of base + 2 month, bonus spread over 10 months


}

// to be created with
// _token is 2KeyEconomy
// TwoKeyPresellExchange(uint256 _rate, address _wallet, ERC20 _token)

// to purchase call:
// buyTokens(address _beneficiary)

// where _beneficiary is an instance of TwoKeyPresellVesting


