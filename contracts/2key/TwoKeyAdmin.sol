pragma solidity ^0.4.24; 

import './TwoKeyEconomy.sol';
import './TwoKeyUpgradableExchange.sol';
import "../interfaces/IAdminContract.sol";
import "../interfaces/IERC20.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyRegistry.sol";
import "./Upgradeable.sol";

contract TwoKeyAdmin is Upgradeable {

	TwoKeyEconomy twoKeyEconomy;
	TwoKeyUpgradableExchange twoKeyUpgradableExchange;
	TwoKeyEventSource twoKeyEventSource;
	TwoKeyRegistry twoKeyReg;

	address public twoKeyCongress;
	address public newTwoKeyAdminAddress;

    bool private initialized = false;

    /// @notice Modifier will revert if calling address is not a member of electorateAdmins
	modifier onlyTwoKeyCongress {
		require(msg.sender == twoKeyCongress);
	    _;
	}

    /// @notice Modifier will revert if caller is not TwoKeyUpgradableExchange
    modifier onlyTwoKeyUpgradableExchange {
        require(msg.sender == address(twoKeyUpgradableExchange));
        _;
    }

    /**
     * @notice Function to set initial parameters in the contract including singletones
     * @param _twoKeyCongress is the address of TwoKeyCongress
     * @param _economy is the address of TwoKeyEconomy
     * @param _exchange is the address of TwoKeyUpgradableExchange
     * @param _twoKeyRegistry is the address of TwoKeyRegistry
     * @param _eventSource is the address of TwoKeyEventSource
     * @dev This function can be called only once, which will be done immediately after deployment.
     */
    function setInitialParams(
        address _twoKeyCongress,
        address _economy,
        address _exchange,
        address _twoKeyRegistry,
        address _eventSource
    ) external {
        require(initialized == false);
        twoKeyCongress = _twoKeyCongress;
        twoKeyReg = TwoKeyRegistry(_twoKeyRegistry);
        twoKeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
        twoKeyEconomy = TwoKeyEconomy(_economy);
        twoKeyEventSource = TwoKeyEventSource(_eventSource);
        initialized = true;
    }

    /// @notice Function where only elected admin can transfer tokens to an address
    /// @dev We're recurring to address different from address 0 and token amount greater than 0
    /// @param _to receiver's address
    /// @param _tokens is token amounts to be transfers
	function transferByAdmins(address _to, uint256 _tokens) external onlyTwoKeyCongress {
		require (_to != address(0) && _tokens > 0);
		twoKeyEconomy.transfer(_to, _tokens);
	}

    /// @notice Function where only elected admin can transfer ether to an address
    /// @dev We're recurring to address different from address 0 and amount greater than 0
    /// @param to receiver's address
    /// @param amount of ether to be transferred
	function transferEtherByAdmins(address to, uint256 amount) external onlyTwoKeyCongress {
		require(to != address(0)  && amount > 0);
		to.transfer(amount);
	}

    /// @notice Function will transfer contract balance to owner if contract was never replaced else will transfer the funds to the new Admin contract address
	function destroy() public onlyTwoKeyCongress {
        selfdestruct(twoKeyCongress);
	}

	/// @notice Function to add moderator
	/// @param _address is address of moderator
	function addMaintainerForRegistry(address _address) public onlyTwoKeyCongress {
		require (_address != address(0));
		twoKeyReg.addTwoKeyMaintainer(_address);
	}

    /// @notice Function to whitelist address as an authorized user for twoKeyEventSource contract
	/// @param _maintainers is array of addresses of maintainers
	function twoKeyEventSourceAddMaintainer(address [] _maintainers) public onlyTwoKeyCongress{
		require(_maintainers.length > 0);
		twoKeyEventSource.addMaintainers(_maintainers);
	}

    /// @notice Function to whitelist contract address for Event Source contract
	/// @dev We're requiring contract address different from address 0 as it is required to be deployed before calling this method
	/// @param _contractAddress is address of a contract
	function twoKeyEventSourceWhitelistContract(address _contractAddress) public onlyTwoKeyCongress {
		require(_contractAddress != address(0));
		twoKeyEventSource.addContract(_contractAddress);
	}

    /// @notice Function to add/update name - address pair from twoKeyAdmin
	/// @param _name is name of user
	/// @param _addr is address of user
    function addNameToReg(string _name, address _addr, string fullName, string email) public {
    	twoKeyReg.addName(_name, _addr, fullName, email);
    }

    /// @notice Function to update twoKeyUpgradableExchange contract address
	/// @param _exchange is address of new twoKeyUpgradableExchange contract
	function updateExchange(address _exchange) public  onlyTwoKeyCongress {
		require (_exchange != address(0));
		twoKeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
	}

    /// @notice Function to update twoKeyRegistry contract address
	/// @param _reg is address of new twoKeyRegistry contract
	function updateRegistry(address _reg) public onlyTwoKeyCongress {
		require (_reg != address(0));
		twoKeyReg = TwoKeyRegistry(_reg);
	}

    /// @notice Function to update twoKeyEventSource contract address
	/// @param _eventSource is address of new twoKeyEventSource contract
	function updateEventSource(address _eventSource) public onlyTwoKeyCongress {
		require (_eventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_eventSource);
	}

	/// @notice Function to freeze all transfers for 2KEY token
	function freezeTransfersInEconomy() public onlyTwoKeyCongress {
		IERC20(address(twoKeyEconomy)).freezeTransfers();
	}

	/// @notice Function to unfreeze all transfers for 2KEY token
	function unfreezeTransfersInEconomy() public onlyTwoKeyCongress {
		IERC20(address(twoKeyEconomy)).unfreezeTransfers();
	}

	//TODO: Backdoor function, delete (modify) once
    function transfer2KeyTokens(address _to, uint256 _amount) public returns (bool) {
		bool completed = twoKeyEconomy.transfer(_to, _amount);
		return completed;
	}

	
	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyEconomy contract address 
	/// @return _economy is address of twoKeyEconomy contract 
    function getTwoKeyEconomy() public view returns(address)  {
    	return address(twoKeyEconomy);
    }
	
	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyReg contract address 
	/// @return _address is address of twoKeyReg contract
    function getTwoKeyReg() public view returns(address)  {
    	return address(twoKeyReg);
    }

    /// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyUpgradableExchange contract address 
	/// @return _address is address of twoKeyUpgradableExchange contract
    function getTwoKeyUpgradableExchange() public view returns(address)  {
    	return address(twoKeyUpgradableExchange);
    }

	/// @notice Fallback function will transfer payable value to new admin contract if admin contract is replaced else will be stored this the exist admin contract as it's balance
	/// @dev A payable fallback method
	function() public payable {

    }
    
} 