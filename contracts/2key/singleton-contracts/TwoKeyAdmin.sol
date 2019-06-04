pragma solidity ^0.4.24;

import './TwoKeyEconomy.sol';
import './TwoKeyUpgradableExchange.sol';
import "./TwoKeyEventSource.sol";
import "./TwoKeyRegistry.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IMaintainingPattern.sol";
import "../Upgradeable.sol";

//TODO: Add all the missing functions from other singletones which can be called by TwoKeyAdmin
contract TwoKeyAdmin is Upgradeable {

	TwoKeyEconomy twoKeyEconomy;
	TwoKeyUpgradableExchange twoKeyUpgradableExchange;
	TwoKeyEventSource twoKeyEventSource;
	TwoKeyRegistry twoKeyReg;


	address public twoKeyCongress;
	address public newTwoKeyAdminAddress;

	uint twoKeyIntegratorDefaultFeePercent; // 2% is default value for this
	uint twoKeyNetworkTaxPercent; //2% is default value for this
	uint twoKeyTokenRate;
	uint rewardReleaseAfter;

    bool initialized = false;

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
        address _eventSource,
		uint _twoKeyTokenReleaseDate
    ) external {
        require(initialized == false);
        twoKeyIntegratorDefaultFeePercent = 2;
		twoKeyNetworkTaxPercent = 2;
		twoKeyTokenRate = 95; //The actual rate is 95 / 1000 = 0.095$
        twoKeyCongress = _twoKeyCongress;
        twoKeyReg = TwoKeyRegistry(_twoKeyRegistry);
        twoKeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
        twoKeyEconomy = TwoKeyEconomy(_economy);
        twoKeyEventSource = TwoKeyEventSource(_eventSource);
        initialized = true;
		rewardReleaseAfter = _twoKeyTokenReleaseDate; //01/01/2020
    }

    /// @notice Function where only elected admin can transfer tokens to an address
    /// @dev We're recurring to address different from address 0 and token amount greater than 0
    /// @param _to receiver's address
    /// @param _tokens is token amounts to be transfers
	function transferByAdmins(
		address _to,
		uint256 _tokens
	)
	external
	onlyTwoKeyCongress
	{
		require (_to != address(0) && _tokens > 0);
		twoKeyEconomy.transfer(_to, _tokens);
	}

    /// @notice Function where only elected admin can transfer ether to an address
    /// @dev We're recurring to address different from address 0 and amount greater than 0
    /// @param to receiver's address
    /// @param amount of ether to be transferred
	function transferEtherByAdmins(
		address to,
		uint256 amount
	)
	external
	onlyTwoKeyCongress
	{
		require(to != address(0)  && amount > 0);
		to.transfer(amount);
	}

    /// @notice Function will transfer contract balance to owner if contract was never replaced else will transfer the funds to the new Admin contract address
	function destroy()
	public
	onlyTwoKeyCongress
	{
        selfdestruct(twoKeyCongress);
	}

    /// @notice Function to add/update name - address pair from twoKeyAdmin
	/// @param _name is name of user
	/// @param _addr is address of user
    function addNameToReg(
		string _name,
		address _addr,
		string fullName,
		string email,
		bytes signature
	) external {
    	twoKeyReg.addName(_name, _addr, fullName, email, signature);
    }

    /// @notice Function to update twoKeyUpgradableExchange contract address
	/// @param _exchange is address of new twoKeyUpgradableExchange contract
	function updateExchange(
		address _exchange
	)
	external
	onlyTwoKeyCongress
	{
		require (_exchange != address(0));
		twoKeyUpgradableExchange = TwoKeyUpgradableExchange(_exchange);
	}

	/// @notice Function to update reward release date
	function updateRewardsRelease(uint newRewardReleaseAfter)
	external
	onlyTwoKeyCongress
	{
		require (now <= newRewardReleaseAfter && now <= rewardReleaseAfter);
		rewardReleaseAfter = newRewardReleaseAfter;
	}

    /// @notice Function to update twoKeyRegistry contract address
	/// @param _reg is address of new twoKeyRegistry contract
	function updateRegistry(
		address _reg
	)
	external
	onlyTwoKeyCongress
	{
		require (_reg != address(0));
		twoKeyReg = TwoKeyRegistry(_reg);
	}

    /// @notice Function to update twoKeyEventSource contract address
	/// @param _eventSource is address of new twoKeyEventSource contract
	function updateEventSource(
		address _eventSource
	)
	external
	onlyTwoKeyCongress
	{
		require (_eventSource != address(0));
		twoKeyEventSource = TwoKeyEventSource(_eventSource);
	}

	/// @notice Function to freeze all transfers for 2KEY token
	function freezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		IERC20(address(twoKeyEconomy)).freezeTransfers();
	}

	/// @notice Function to unfreeze all transfers for 2KEY token
	function unfreezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		IERC20(address(twoKeyEconomy)).unfreezeTransfers();
	}

    function transfer2KeyTokens(
		address _to,
		uint256 _amount
	)
	public
	onlyTwoKeyCongress
	returns (bool)
	{
		bool completed = twoKeyEconomy.transfer(_to, _amount);
		return completed;
	}


	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyEconomy contract address
	/// @return _economy is address of twoKeyEconomy contract
    function getTwoKeyEconomy()
	external
	view
	returns(address)
	{
    	return address(twoKeyEconomy);
    }

	/// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyReg contract address
	/// @return _address is address of twoKeyReg contract
    function getTwoKeyReg()
	external
	view
	returns(address)
	{
    	return address(twoKeyReg);
    }


	function getTwoKeyRewardsReleaseDate()
	external
	view
	returns(uint)
	{
		return rewardReleaseAfter;
	}

    /// View function - doesn't cost any gas to be executed
	/// @notice Function to fetch twoKeyUpgradableExchange contract address
	/// @return _address is address of twoKeyUpgradableExchange contract
    function getTwoKeyUpgradableExchange()
	external
	view
	returns(address)
	{
    	return address(twoKeyUpgradableExchange);
    }

	/// @notice Fallback function will transfer payable value to new admin contract if admin contract is replaced else will be stored this the exist admin contract as it's balance
	/// @dev A payable fallback method
	function() external payable {

    }

	function addMaintainersToSelectedSingletone(
		address destinationContract,
		address [] maintainers
	)
	external
	onlyTwoKeyCongress
	{
		IMaintainingPattern(destinationContract).addMaintainers(maintainers);
	}

	function deleteMaintainersFromSelectedSingletone(
		address destinationContract,
		address [] maintainers
	)
	external
	onlyTwoKeyCongress
	{
		IMaintainingPattern(destinationContract).removeMaintainers(maintainers);
	}

	function changeDefaultIntegratorFeePercent(
		uint newFee
	)
	public
	onlyTwoKeyCongress
	{
		twoKeyIntegratorDefaultFeePercent = newFee;
	}

	function getDefaultIntegratorFeePercent()
	public
	view
	returns (uint)
	{
		return twoKeyIntegratorDefaultFeePercent;
	}

	function changeDefaulTwoKeyNetworkTaxPercent(
		uint newTaxPercent
	)
	public
	onlyTwoKeyCongress
	{
		twoKeyNetworkTaxPercent = newTaxPercent;
	}

	function getDefaultNetworkTaxPercent()
	public
	view
	returns (uint)
	{
		return twoKeyNetworkTaxPercent;
	}

	function updateTwoKeyTokenRate(
		uint newRate
	)
	public
	onlyTwoKeyCongress
	{
		twoKeyTokenRate = newRate;
	}

	function getTwoKeyTokenRate()
	public
	view
	returns (uint)
	{
		return twoKeyTokenRate;
	}
}
