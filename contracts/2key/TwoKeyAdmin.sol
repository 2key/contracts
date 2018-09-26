pragma solidity ^0.4.24; 

import '../openzeppelin-solidity/contracts/lifecycle/Destructible.sol';
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';

import './TwoKeyEconomy.sol';
import './TwoKeyUpgradableExchange.sol';
import "../interfaces/IAdminContract.sol";
import "../interfaces/IERC20.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyReg.sol";

// SAFT are to be implemented by transferEtherByAdmins with the amount including the discount, according to the prevailing rate

contract TwoKeyAdmin is  Ownable, Destructible, AdminContract {


	// TODO: Add permission modifiers to all functions @Amit

	TwoKeyEconomy private twoKeyEconomy;
	TwoKeyUpgradableExchange private twokeyUpgradableExchange;
	TwoKeyEventSource private twoKeyEventSource;
	TwoKeyReg private twoKeyReg;
	TwoKeyAdmin private previousAdmin;

	address private electorateAdmins;
	address private newTwoKeyAdminAddress;
	bool private wasReplaced;

	constructor(
		address _electorateAdmins		
	) Ownable() Destructible() payable public {
		require(_electorateAdmins != address(0));
		wasReplaced = false;
		electorateAdmins = _electorateAdmins;
	}

    
    /// @notice Function where only elected admin can replace the exisitng admin contract with new admin contract. 
    /// @dev This method is expected to transfer it's current economy to new admin contract
    /// @param _newAdminContract is address of New Admin Contract
	function replaceOneself(address _newAdminContract) external wasNotReplaced adminsVotingApproved {
		uint balanceOfOldAdmin = twoKeyEconomy.balanceOf(address(this));
		TwoKeyAdmin newAdminContractObject = TwoKeyAdmin(_newAdminContract);
		newTwoKeyAdminAddress = _newAdminContract;
		twoKeyEconomy.transfer(_newAdminContract, balanceOfOldAdmin);
		string memory admin = twoKeyEconomy.getAdminRole();
		twoKeyEconomy.adminAddRole(_newAdminContract, admin);
		newAdminContractObject.transfer(address(this).balance);
		newAdminContractObject.setSingletones(twoKeyEconomy, twokeyUpgradableExchange, twoKeyReg, twoKeyEventSource);
		wasReplaced = true;
		twoKeyEventSource.changeAdmin(_newAdminContract);
	}

	/// @notice Function to add the address of previous active admin contract
	/// @param _previousAdmin is address of previous active admin contract
	function addPreviousAdmin(address _previousAdmin) adminsVotingApproved {
		require(_previousAdmin != address(0));
		previousAdmin = TwoKeyAdmin(_previousAdmin);
	}

    /// @notice Function where only elected admin can transfer tokens to an address
    /// @dev We're recuring to address different from address 0 and token amount greator than 0
    /// @param _to receiver's address
    /// @param _tokens is token amounts to be transfers
	function transferByAdmins(address _to, uint256 _tokens) external wasNotReplaced adminsVotingApproved {
		require (_to != address(0) && _tokens > 0);
		twoKeyEconomy.transfer(_to, _tokens);
	}

    /// @notice Function where only elected admin can upgrade exchange contract address
    /// @dev We're recuring newExchange address different from address 0
    /// @param newExchange is New Upgradable Exchange contract address
	function upgradeEconomyExchangeByAdmins(address newExchange) external wasNotReplaced adminsVotingApproved {
		require (newExchange != address(0));
		twokeyUpgradableExchange.upgrade(newExchange);
	}

    /// @notice Function where only elected admin can transfer ethers to an address
    /// @dev We're recuring to address different from address 0 and amount greator than 0
    /// @param to receiver's address
    /// @param amount of ethers to be transfers
	function transferEtherByAdmins(address to, uint256 amount) external wasNotReplaced adminsVotingApproved {
		require(to != address(0)  && amount > 0);
		to.transfer(amount);
	}

	// lifecycle methods
	/// @notice Function will transfer payable value to new admin contract if admin contract is replaced else will be stored this the exisitng admin contract as it's balance
	/// @dev A payable fallback method
	function() public payable {
		if (wasReplaced) {
			newTwoKeyAdminAddress.transfer(msg.value);
		}
	}

    /// @notice Function will transfer contract balance to owner if contract was never replaced else will transfer the funds to the new Admin contract address  
	function destroy() public adminsVotingApproved {
		if (!wasReplaced)
			selfdestruct(owner);
		else
			selfdestruct(newTwoKeyAdminAddress);
	}

	// modifiers
    /// @notice Modifier will revert if calling address is not owner or previous active admin contract
	modifier onlyAuthorizedAdmins() {
		require((msg.sender == owner) || (msg.sender == address(previousAdmin)));
	   _;
	}

    /// @notice Modifier will revert if calling address is not a member of electorateAdmins 
	modifier adminsVotingApproved() {
		require(msg.sender == electorateAdmins);
	    _;
	}

    /// @notice Modifier will revert if contract is already replaced 
	modifier wasNotReplaced() {
		require(!wasReplaced);
		_;
	}

    /// @notice Function to whitelist address as an authorized user for twoKeyEventSource contract
	/// @param _address is address of user
	function twoKeyEventSourceAddAuthorizedAddress(address _address) public {
		require(_address != address(0));
		twoKeyEventSource.addAuthorizedAddress(_address);
	}

    /// @notice Function to add twoKeyEventSource contract to twoKeyAdmin 
	/// @dev We're requiring twoKeyEventSource contract address different from address 0 as it is required to be deployed before calling this method
	/// @param _twoKeyEventSource is address of twoKeyEventSource contract address
	function addTwoKeyEventSource(address _twoKeyEventSource) public {
		require(_twoKeyEventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_twoKeyEventSource);
	}

    /// @notice Function to whitelist contract address for Event Source contract 
	/// @dev We're requiring contract address different from address 0 as it is required to be deployed before calling this method
	/// @param _contractAddress is address of a contract
	function twoKeyEventSourceAddAuthorizedContracts(address _contractAddress) public {
		require(_contractAddress != address(0));
		twoKeyEventSource.addContract(_contractAddress);
	}

    /// @notice Function to add/update name - address pair from twoKeyAdmin
	/// @param _name is name of user
	/// @param _addr is address of user
    function addNameToReg(string _name, address _addr) public {
    	twoKeyReg.addName(_name, _addr);
    }
    
    /// @notice Function to update twoKeyUpgradableExchange contract address
	/// @param _exchange is address of new twoKeyUpgradableExchange contract
	function updateExchange(address _exchange) public  adminsVotingApproved {
		require (_exchange != address(0));
		twokeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
	}

    /// @notice Function to update twoKeyRegistry contract address
	/// @param _reg is address of new twoKeyRegistry contract
	function updateRegistry(address _reg) public adminsVotingApproved {
		require (_reg != address(0));
		twoKeyReg = TwoKeyReg(_reg);		
	}

    /// @notice Function to update twoKeyEventSource contract address
	/// @param _eventSource is address of new twoKeyEventSource contract
	function updateEventSource(address _eventSource) public adminsVotingApproved {
		require (_eventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_eventSource);
	}

 	/// @notice Function to set Singletones contract address 
	/// @dev We're requiring contract addresses different from address 0 as they are required to be deployed before calling this method
	/// @param _economy is address of twoKeyEconomy contract address
	/// @param _exchange is address of twoKeyExchange contract address
	/// @param _reg is address of twoKeyReg contract address
    function setSingletones(address _economy, address _exchange, address _reg, address _eventSource) public onlyAuthorizedAdmins {
		//this is only for first time deployment of admin contract and other singletons
		require(twoKeyEconomy == address(0));
		require(twoKeyReg == address(0));
		require(twokeyUpgradableExchange == address(0));
		require(twoKeyEventSource == address(0));

		require(_economy != address(0));
    	require(_exchange != address(0));
    	require(_reg != address(0));
    	require(_eventSource != address(0));

		twoKeyReg = TwoKeyReg(_reg);
    	twokeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
		twoKeyEconomy = TwoKeyEconomy(_economy);
		twoKeyEventSource = TwoKeyEventSource(_eventSource);
    }

    /// View function - doesn't cost any gas to be executed
	/// @notice Function to get Ether Balance of given address 
	/// @param _addr is address of user
	/// @return Ether balance of given address
	function getEtherBalanceOfAnAddress(address _addr) public view returns (uint256){
		return address(_addr).balance;
	}
	
	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyEconomy contract address 
	/// @return _economy is address of twoKeyEconomy contract 
    function getTwoKeyEconomy () public view returns(address _economy)  {
    	return address(twoKeyEconomy);
    }


	function transfer2KeyTokens(address _economy, address _to, uint _amount) public returns (bool) {
		bool completed = IERC20(address(_economy)).transfer(_to, _amount);
		return completed;
	}
	
	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyReg contract address 
	/// @return _address is address of twoKeyReg contract
    function getTwoKeyReg () public view returns(address _address)  {
    	return address(twoKeyReg);
    }

    /// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyUpgradableExchange contract address 
	/// @return _address is address of twoKeyUpgradableExchange contract
    function getTwoKeyUpgradableExchange () public view returns(address _exchange)  {
    	return address(twokeyUpgradableExchange);
    }
    
} 