pragma solidity ^0.4.24; 

import '../openzeppelin-solidity/contracts/lifecycle/Destructible.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './TwoKeyEconomy.sol';
import './TwoKeyUpgradableExchange.sol';
import "../interfaces/IAdminContract.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyReg.sol";



// SAFT are to be implemented by transferEtherByAdmins with the amount including the discount, according to the prevailing rate

contract TwoKeyAdmin is  Ownable, Destructible, AdminContract {

	

	TwoKeyEconomy private economy;
	address private electorateAdmins;
	TwoKeyUpgradableExchange private exchange;
	address private newTwoKeyAdminAddress;
	bool private wasReplaced; 
	TwoKeyEventSource twoKeyEventSource;
	TwoKeyReg private twoKeyReg;

	constructor(
		address _electorateAdmins,
		TwoKeyUpgradableExchange _exchange
	) Ownable() Destructible() payable public {
		require(_electorateAdmins != address(0));
		require(_exchange != address(0));
		wasReplaced = false;
		exchange = _exchange;
		electorateAdmins = _electorateAdmins;	
	}

	function replaceOneself(address newAdminContract) external wasNotReplaced adminsVotingApproved {
		// take care of : twoKeyReg, TwoKeyEconomy, twoKeyEventSource,TwoKeyUpgradableExchange

		//AdminContract adminContract = AdminContract(newAdminContract);
		//uint balanceOfOldAdmin = economy.balanceOf(adminContract);
		
		uint balanceOfOldAdmin = economy.balanceOf(address(this	));
		TwoKeyAdmin newAdminContractObject= TwoKeyAdmin(newAdminContract);
		newTwoKeyAdminAddress=newAdminContract;

		// move to deploy
		// assign default values to new admin here:
		 newAdminContractObject.SetTwoKeyEonomy(economy);
		//newAdminContract.SetTwoKeyExchange(exchange);
		 newAdminContractObject.SetTwoKeyReg(twoKeyReg);


		wasReplaced = true;

		economy.transfer(newAdminContract, balanceOfOldAdmin);	
		//economy.transferOwnership(newAdminContract);

		//economy.transferOwnership(newAdminContract)
		economy.adminAddRole(newAdminContract,"admin");
		//exchange.transferOwnership(newAdminContract); // need to take care
		newAdminContract.transfer(address(this).balance);
		//eventsource	
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
			newTwoKeyAdminAddress.transfer(msg.value);
		}
	}

	function destroy() public adminsVotingApproved {
		if (wasReplaced)
			selfdestruct(owner);
		else
			selfdestruct(newTwoKeyAdminAddress);
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

	function twoKeyEventSourceAddAuthorizedContracts(address _contractAddress) public {
		require(_contractAddress != address(0));
		twoKeyEventSource.addContract(_contractAddress);
	}

	// modifier for admin call check
	//<TBD> may be owner
    function SetTwoKeyEonomy(address _economy) public   {
		require(_economy != address(0));
    	economy = TwoKeyEconomy(_economy);

    }

	// modifier for admin call check
	//<TBD> may be owner
    function SetTwoKeyReg(address _address) public  {
		require(_address != address(0));
    	twoKeyReg = TwoKeyReg(_address);

    }

	function SetTwoKeyExchange(address _exchange) public adminsVotingApproved {
		require(_exchange != address(0));
    	exchange = TwoKeyUpgradableExchange(exchange);
    	
    }


// modifier for admin call check
	//<TBD> may be owner
    function GetTwoKeyEconomy () public view  returns(address _economy)  {
    	return address(economy);
    }

    // modifier for admin call check
	//<TBD> may be owner
    function GetTwoKeyReg () public view  returns(address _address)  {
    	return address(twoKeyReg);
    }
    
} 