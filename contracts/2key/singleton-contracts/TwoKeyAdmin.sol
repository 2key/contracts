pragma solidity ^0.4.24;

import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyAdminStorage.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

contract TwoKeyAdmin is Upgradeable, ITwoKeySingletonUtils {

	/**
	 * Storage keys are stored on the top. Here they are in order to avoid any typos
	 */
	string constant _twoKeyIntegratorDefaultFeePercent = "twoKeyIntegratorDefaultFeePercent";
	string constant _twoKeyNetworkTaxPercent = "twoKeyNetworkTaxPercent";
	string constant _twoKeyTokenRate = "twoKeyTokenRate";
	string constant _rewardReleaseAfter = "rewardReleaseAfter";

	bool initialized = false;

	ITwoKeyAdminStorage public PROXY_STORAGE_CONTRACT; //Pointer to storage contract

	address twoKeyCongress; // Address of TwoKeyCongress (logic)
	address twoKeyEconomy; // Address of TwoKeyEconomy (2KEY ERC20 token)


    /// @notice Modifier which throws if caller is not TwoKeyCongress
	modifier onlyTwoKeyCongress {
		require(msg.sender == twoKeyCongress);
	    _;
	}

    /// @notice Modifier will revert if caller is not TwoKeyUpgradableExchange
    modifier onlyTwoKeyUpgradableExchange {
		address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        require(msg.sender == address(twoKeyUpgradableExchange));
        _;
    }

    /**
     * @notice Function to set initial parameters in the contract including singletones
     * @param _twoKeySingletonRegistry is the singletons registry contract address
     * @param _proxyStorageContract is the address of proxy for storage for this contract
     * @param _twoKeyCongress is the address of TwoKeyCongress
     * @param _economy is the address of TwoKeyEconomy
     * @dev This function can be called only once, which will be done immediately after deployment.
     */
    function setInitialParams(
		address _twoKeySingletonRegistry,
		address _proxyStorageContract,
        address _twoKeyCongress,
        address _economy,
		uint _twoKeyTokenReleaseDate
    ) external {
        require(initialized == false);

		TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
		PROXY_STORAGE_CONTRACT = ITwoKeyAdminStorage(_proxyStorageContract);
		twoKeyCongress = _twoKeyCongress;
		twoKeyEconomy = _economy;

		setUint(_twoKeyIntegratorDefaultFeePercent,2);
		setUint(_twoKeyNetworkTaxPercent,25);
		setUint(_twoKeyTokenRate, 95);
		setUint(_rewardReleaseAfter, _twoKeyTokenReleaseDate);

        initialized = true;
    }


    /// @notice Function where only TwoKeyCongress can transfer ether to an address
    /// @dev We're recurring to address different from address 0
    /// @param to receiver's address
    /// @param amount of ether to be transferred
	function transferEtherByAdmins(
		address to,
		uint256 amount
	)
	external
	onlyTwoKeyCongress
	{
		require(to != address(0));
		to.transfer(amount);
	}


    /// @notice Function to add/update name - address pair from twoKeyAdmin
	/// @param _name is name of user
	/// @param _addr is address of user
	/// @param _fullName is full name of the user
	/// @param _email is the email of the user
	/// @param _signature is the signature generated on client side
    function addNameToReg(
		string _name,
		address _addr,
		string _fullName,
		string _email,
		bytes _signature
	) external {
		address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry");
    	ITwoKeyReg(twoKeyRegistry).addName(_name, _addr, _fullName, _email, _signature);
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

	/// @notice Function to transfer 2key tokens
	/// @dev only TwoKeyCongress can call this function
	/// @param _to is tokens receiver
	/// @param _amount is the amount of tokens to be transferred
    function transfer2KeyTokens(
		address _to,
		uint256 _amount
	)
	public
	onlyTwoKeyCongress
	returns (bool)
	{
		bool completed = IERC20(twoKeyEconomy).transfer(_to, _amount);
		return completed;
	}

	/// @notice Getter for all integers we'd like to store
	/// @param key is the key (var name)
	function getUint(
		string key
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(key));
	}

	/// @notice Setter for all integers we'd like to store
	/// @param key is the key (var name)
	/// @param value is the value of integer we'd like to store
	function setUint(
		string key,
		uint value
	)
	internal
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(key), value);
	}

	/// @notice Getter function for TwoKeyRewardsReleaseDate
	function getTwoKeyRewardsReleaseDate()
	external
	view
	returns(uint)
	{
		return getUint(_rewardReleaseAfter);
	}

	/// @notice Getter function for TwoKeyIntegratorDefaultFeePercent
	function getDefaultIntegratorFeePercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyIntegratorDefaultFeePercent);
	}

	/// @notice Getter function for TwoKeyNetworkTaxPercent
	function getDefaultNetworkTaxPercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyNetworkTaxPercent);
	}

	/// @notice Getter function for TwoKeyTokenRate
	function getTwoKeyTokenRate()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyTokenRate);
	}

	function setNewTwoKeyRewardsReleaseDate(
		uint newDate
	)
	external
	onlyTwoKeyCongress
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_rewardReleaseAfter),newDate);
	}

	function setDefaultIntegratorFeePercent(
		uint newFeePercent
	)
	external
	onlyTwoKeyCongress
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_twoKeyIntegratorDefaultFeePercent),newFeePercent);
	}


	/// Fallback function
	function()
	external
	payable
	{

	}

}
