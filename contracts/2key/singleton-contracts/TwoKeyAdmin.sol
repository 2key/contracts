pragma solidity ^0.4.24;

import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../interfaces/storage-contracts/ITwoKeyAdminStorage.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyDeepFreezeTokenPool.sol";
import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../libraries/SafeMath.sol";

contract TwoKeyAdmin is Upgradeable, ITwoKeySingletonUtils {

	using SafeMath for *;

	/**
	 * Storage keys are stored on the top. Here they are in order to avoid any typos
	 */
	string constant _twoKeyIntegratorDefaultFeePercent = "twoKeyIntegratorDefaultFeePercent";
	string constant _twoKeyNetworkTaxPercent = "twoKeyNetworkTaxPercent";
	string constant _twoKeyTokenRate = "twoKeyTokenRate";
	string constant _rewardReleaseAfter = "rewardReleaseAfter";
	string constant _rewardsReceivedAsModeratorTotal = "rewardsReceivedAsModeratorTotal";

	/**
	 * Keys for the addresses we're accessing
	 */
	string constant _twoKeyCongress = "TwoKeyCongress";
	string constant _twoKeyUpgradableExchange = "TwoKeyUpgradableExchange";
	string constant _twoKeyRegistry = "TwoKeyRegistry";
	string constant _twoKeyEconomy = "TwoKeyEconomy";
	string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
	string constant _twoKeyEventSource = "TwoKeyEventSource";


	bool initialized = false;
	ITwoKeyAdminStorage public PROXY_STORAGE_CONTRACT; //Pointer to storage contract


    /// @notice Modifier which throws if caller is not TwoKeyCongress
	modifier onlyTwoKeyCongress {
		require(msg.sender == getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyCongress));
	    _;
	}

	modifier onlyAllowedContracts {
		address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
		require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
		_;
	}


    /**
     * @notice Function to set initial parameters in the contract including singletones
     * @param _twoKeySingletonRegistry is the singletons registry contract address
     * @param _proxyStorageContract is the address of proxy for storage for this contract
     * @dev This function can be called only once, which will be done immediately after deployment.
     */
    function setInitialParams(
		address _twoKeySingletonRegistry,
		address _proxyStorageContract,
		uint _twoKeyTokenReleaseDate
    ) external {
        require(initialized == false);

		TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
		PROXY_STORAGE_CONTRACT = ITwoKeyAdminStorage(_proxyStorageContract);

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



	/**
	 * @notice Function to forward call from congress to the Maintainers Registry and add core devs
	 * @param _coreDevs is the array of core devs to be added to the system
	 */
	function addCoreDevsToMaintainerRegistry(
		address [] _coreDevs
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).addCoreDevs(_coreDevs);
	}



	/**
	 * @notice Function to forward call from congress to the Maintainers Registry and add maintainers
	 * @param _maintainers is the array of core devs to be added to the system
	 */
	function addMaintainersToMaintainersRegistry(
		address [] _maintainers
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).addMaintainers(_maintainers);
	}



	/**
	 * @notice Function to forward call from congress to the Maintainers Registry and remove core devs
	 * @param _coreDevs is the array of core devs to be removed from the system
	 */
	function removeCoreDevsFromMaintainersRegistry(
		address [] _coreDevs
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).removeCoreDevs(_coreDevs);
	}



	/**
	 * @notice Function to forward call from congress to the Maintainers Registry and remove maintainers
	 * @param _maintainers is the array of maintainers to be removed from the system
	 */
	function removeMaintainersFromMaintainersRegistry(
		address [] _maintainers
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).removeMaintainers(_maintainers);
	}



	/// @notice Function to freeze all transfers for 2KEY token
	function freezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).freezeTransfers();
	}



	/// @notice Function to unfreeze all transfers for 2KEY token
	function unfreezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).unfreezeTransfers();
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
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		bool completed = IERC20(twoKeyEconomy).transfer(_to, _amount);
		return completed;
	}


	function updateReceivedTokensAsModerator(
		uint amountOfTokens
	)
	public
	onlyAllowedContracts
	{

		uint networkFee = getDefaultIntegratorFeePercent();
		uint moderatorTokens = amountOfTokens.mul(100 - networkFee).div(100);

		bytes32 keyHashTotalRewards = keccak256(_rewardsReceivedAsModeratorTotal);
		PROXY_STORAGE_CONTRACT.setUint(keyHashTotalRewards, moderatorTokens.add((PROXY_STORAGE_CONTRACT.getUint(keyHashTotalRewards))));

		//Emit event through TwoKeyEventSource for the campaign
		ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource)).emitReceivedTokensAsModerator(msg.sender, moderatorTokens);

		//Update moderator earnings to campaign
		ITwoKeyCampaign(msg.sender).updateModeratorRewards(moderatorTokens);

		//Now update twoKeyDeepFreezeTokenPool
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		address deepFreezeTokenPool = getAddressFromTwoKeySingletonRegistry("TwoKeyDeepFreezeTokenPool");

		uint tokensForDeepFreezeTokenPool = amountOfTokens.sub(moderatorTokens);
		//Transfer tokens to deep freeze token pool
		IERC20(twoKeyEconomy).transfer(deepFreezeTokenPool, tokensForDeepFreezeTokenPool);

//		//Update contract on receiving tokens
		ITwoKeyDeepFreezeTokenPool(deepFreezeTokenPool).updateReceivedTokensForSuccessfulConversions(tokensForDeepFreezeTokenPool, msg.sender);
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
		uint256 newDate
	)
	public
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

	function getAmountOfTokensReceivedAsModerator()
	public
	view
	returns (uint)
	{
		PROXY_STORAGE_CONTRACT.getUint(keccak256(_rewardsReceivedAsModeratorTotal));
	}

	/// Fallback function
	function()
	external
	payable
	{

	}

}
