pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/lifecycle/Destructible.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './TwoKeyEconomy.sol';
import './TwoKeyUpgradableExchange.sol';
import "../interfaces/IAdminContract.sol";
import "./TwoKeyEventSource.sol";



// SAFT are to be implemented by transferEtherByAdmins with the amount including the discount, according to the prevailing rate

contract TwoKeyAdmin is Ownable, Destructible, AdminContract {

	TwoKeyEconomy economy;
	address electorateAdmins;
	TwoKeyUpgradableExchange exchange;
	address public newAdmin;
	bool wasReplaced; 
	TwoKeyEventSource twoKeyEventSource;

	constructor(
		TwoKeyEconomy _economy, 
		address _electorateAdmins,
		TwoKeyUpgradableExchange _exchange
	) Ownable() Destructible() payable public {
		require(_economy != address(0));
		require(_electorateAdmins != address(0));
		require(_exchange != address(0));
		wasReplaced = false;
		economy = _economy;
		exchange = _exchange;
		electorateAdmins = _electorateAdmins;	
	}

	function replaceOneself(address newAdminContract) external wasNotReplaced adminsVotingApproved {
		AdminContract adminContract = AdminContract(newAdminContract);
		uint balanceOfOldAdmin = economy.balanceOf(adminContract);
		// move to deploy
		wasReplaced = true;	
		economy.transfer(newAdminContract, balanceOfOldAdmin);	
		economy.transferOwnership(newAdminContract);
		exchange.transferOwnership(newAdminContract);
		newAdminContract.transfer(address(this).balance);	
	}

	function transferByAdmins(address _to, uint256 _tokens) external wasNotReplaced adminsVotingApproved {
		economy.transfer(_to, _tokens);
	}


	function upgradeEconomyExchangeByAdmins(address newExchange) external wasNotReplaced adminsVotingApproved {
		if (newExchange != address(0))
			exchange.upgrade(newExchange);
	}

	function transferEtherByAdmins(address to, uint256 amount) external wasNotReplaced adminsVotingApproved {
		require(to != address(0)  && amount > 0);
		to.transfer(amount);
	}


	// lifecycle methods

	function() public payable {
		if (wasReplaced) {
			newAdmin.transfer(msg.value);
		}
	}

	function destroy() public adminsVotingApproved {
		if (wasReplaced)
			selfdestruct(owner);
		else
			selfdestruct(newAdmin);
	}

	// modifiers
	modifier adminsVotingApproved() {
		require(msg.sender == electorateAdmins);
	    _;
	}

	modifier wasNotReplaced() {
		require(!wasReplaced);
		_;
	}

	function twoKeyEventSourceAddAuthorizedAddress(address _address) public {
		require(_address != address(0));
		twoKeyEventSource.addAuthorizedAddress(_address);
	}
	function addTwoKeyEventSource(address _twoKeyEventSource) public {
		require(_twoKeyEventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_twoKeyEventSource);
	}
}