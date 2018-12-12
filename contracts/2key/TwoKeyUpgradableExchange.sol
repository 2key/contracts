pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract TwoKeyUpgradableExchange is Crowdsale {

	/// @notice Event is emitted when a user sell his tokens
	event TokenSell(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	modifier onlyAdmin() {
		require(msg.sender == address(admin));
		_;
	}

	//TODO: We should somehow add audited contracts here which will be eligible to buyTokens, not everyone

	constructor(uint256 _rate, address _twoKeyAdmin, ERC20 _token, address _twoKeyUpgradableExchange)
		Crowdsale(_rate, _twoKeyAdmin, _token, _twoKeyUpgradableExchange) public {
	}

    function () public payable {
        buyTokens(msg.sender);
    }
}
