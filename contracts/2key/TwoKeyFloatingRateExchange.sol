pragma solidity ^0.4.24;

import './TwoKeyUpgradableExchange.sol';

contract TwoKeyFloatingRateExchange is TwoKeyUpgradableExchange  {
	function setRate(uint256 _newRate) public onlyOwner {
		require(_newRate > 0);
		rate = _newRate;
	}
}