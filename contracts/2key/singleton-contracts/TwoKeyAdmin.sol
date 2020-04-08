pragma solidity ^0.4.24;

import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../interfaces/storage-contracts/ITwoKeyAdminStorage.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyDeepFreezeTokenPool.sol";
import "../interfaces/ITwoKeyFeeManager.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/IKyberNetworkInterface.sol";
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
	string constant _daiWithdrawnFromUpgradableExchange = "daiWithdrawnFromUpgradableExchange";
	string constant _moderatorEarningsPerCampaign = "moderatorEarningsPerCampaign";


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


	ITwoKeyAdminStorage public PROXY_STORAGE_CONTRACT; 			//Pointer to storage contract


	/**
	 * @notice 			Modifier which throws if caller is not TwoKeyCongress
	 */
	modifier onlyTwoKeyCongress {
		require(msg.sender == getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyCongress));
	    _;
	}


	/**
	 * @notice 			Modifier which throws if the campaign contract sending request is not validated
	 * 					by TwoKeyCampaignValidator contract
	 */
	modifier onlyAllowedContracts {
		address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
		require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
		_;
	}


    /**
     * @notice 			Function to set initial parameters in the contract including singletones
     *
     * @param 			_twoKeySingletonRegistry is the singletons registry contract address
     * @param 			_proxyStorageContract is the address of proxy for storage for this contract
     *
     * @dev 			This function can be called only once, which will be done immediately after deployment.
     */
    function setInitialParams(
		address _twoKeySingletonRegistry,
		address _proxyStorageContract,
		uint _twoKeyTokenReleaseDate
    )
	public
	{
        require(initialized == false);

		TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
		PROXY_STORAGE_CONTRACT = ITwoKeyAdminStorage(_proxyStorageContract);

		setUint(_twoKeyIntegratorDefaultFeePercent,2);
		setUint(_twoKeyNetworkTaxPercent,25);
		setUint(_rewardReleaseAfter, _twoKeyTokenReleaseDate);

        initialized = true;
    }


    /**
     * @notice 			Function where only TwoKeyCongress can transfer ether to an address
     *
     * @dev 			We're recurring to address different from address 0 and value is in WEI
     *
     * @param 			to is representing receiver's address
     * @param 			amount of ether to be transferred

     */
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
	 * @notice 			Function to forward call from congress to the Maintainers Registry and add core devs
	 *
	 * @param 			_coreDevs is the array of core devs to be added to the system
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
	 * @notice 			Function to forward call from congress to the Maintainers Registry and add maintainers
	 *
	 * @param 			_maintainers is the array of core devs to be added to the system
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
	 * @notice 			Function to forward call from congress to the Maintainers Registry and remove core devs
	 *
	 * @param 			_coreDevs is the array of core devs to be removed from the system
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
	 * @notice 			Function to forward call from congress to the Maintainers Registry and remove maintainers
	 *
	 * @param 			_maintainers is the array of maintainers to be removed from the system
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



	/**
	 * @notice 			Function to freeze all transfers for 2KEY token
	 *					Which means that no one transfer of ERC20 2KEY can be performed
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function freezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).freezeTransfers();
	}


	/**
	 * @notice 			Function to unfreeze all transfers for 2KEY token
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function unfreezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).unfreezeTransfers();
	}


	/**
	 * @notice 			Function to transfer 2key tokens from the admin contract
	 * @dev 			only TwoKeyCongress can call this function
	 * @param 			_to is address representing tokens receiver
	 * @param 			_amount is the amount of tokens to be transferred
 	 */
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


    /**
     * @notice 			Function to withdraw collected ether from TwoKeyFeeManager contract
     * 					and it can be done only when TwoKeyCongress does voting on that
     * @dev				Restricted only to TwoKeyCongress contract
     */
    function withdrawEtherCollectedFromFeeManager()
    public
    onlyTwoKeyCongress
    {
        address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
        ITwoKeyFeeManager(twoKeyFeeManager).withdrawEtherCollected();
    }


	/**
	 * @notice 			Function to withdraw any ERC20 we have on TwoKeyUpgradableExchange contract
	 *
	 * @param 			_tokenAddress is the address of the ERC20 token we're willing to take
	 * @param			_amountOfTokens is the amount of the tokens we're willing to withdraw
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function withdrawERC20FromUpgradableExchange(
		address _tokenAddress,
		uint _amountOfTokens
	)
	public
	onlyTwoKeyCongress
	{
		address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
		IUpgradableExchange(twoKeyUpgradableExchange).withdrawERC20(_tokenAddress, _amountOfTokens);
	}


	/**
	 * @notice 			Function which will be used take the tokens from the campaign and distribute
	 * 					them between itself and TwoKeyDeepFreezeTokenPool
	 *
	 * @param			amountOfTokens is the amount of the tokens which are for moderator rewards
 	 */
	function updateReceivedTokensAsModerator(
		uint amountOfTokens
	)
	public
	onlyAllowedContracts
	{
		// Network fee which will be taken from moderator
		uint networkFee = getDefaultNetworkTaxPercent();

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

		//Update contract on receiving tokens
		ITwoKeyDeepFreezeTokenPool(deepFreezeTokenPool).updateReceivedTokensForSuccessfulConversions(tokensForDeepFreezeTokenPool, msg.sender);

		// Compute the hash for the storage for moderator earnings per campaign
		bytes32 keyHashEarningsPerCampaign = keccak256(_moderatorEarningsPerCampaign, msg.sender);
		// Take the current earnings
		uint currentEarningsForThisCampaign = PROXY_STORAGE_CONTRACT.getUint(keyHashEarningsPerCampaign);
		// Increase them by earnings added now and store
		PROXY_STORAGE_CONTRACT.setUint(keyHashEarningsPerCampaign, currentEarningsForThisCampaign.add(moderatorTokens));
	}


    /**
     * @notice          Function to call setLiquidityParams on LiquidityConversionRates.sol
     *                  contract, it can be called only by TwoKeyAdmin.sol contract
     *
     * @param           liquidityConversionRatesContractAddress is the address of liquidity conversion rates contract
                        the right address depending on environment can be found in configurationFiles/kyberAddresses.json
                        It's named "pricing" in the json object
     */
	function setLiquidityParametersInKyber(
        address liquidityConversionRatesContractAddress,
        uint _rInFp,
        uint _pMinInFp,
        uint _numFpBits,
        uint _maxCapBuyInWei,
        uint _maxCapSellInWei,
        uint _feeInBps,
        uint _maxTokenToEthRateInPrecision,
        uint _minTokenToEthRateInPrecision
	)
	public
	onlyTwoKeyCongress
	{
        // Call on the contract set liquidity params
        IKyberNetworkInterface(liquidityConversionRatesContractAddress).setLiquidityParams(
            _rInFp,
            _pMinInFp,
            _numFpBits,
            _maxCapBuyInWei,
            _maxCapSellInWei,
            _feeInBps,
            _maxTokenToEthRateInPrecision,
            _minTokenToEthRateInPrecision
        );
	}


    /**
     * @notice          Function to call withdraw on KyberReserve.sol contract
     *                  It can be only called by TwoKeyAdmin.sol contract
     *
     * @param           kyberReserveContractAddress is the address of kyber reserve contract
     *                  right address depending on environment can be found in configurationFiles/kyberAddresses.json
                        It's named "reserve" in the json object
     */
    function withdrawTokensFromKyberReserve(
        address kyberReserveContractAddress,
        ERC20 tokenToWithdraw,
        uint amountToBeWithdrawn,
        address receiverAddress
    )
    public
    onlyTwoKeyCongress
    {
        // Call on the contract withdraw function
        IKyberNetworkInterface(kyberReserveContractAddress).withdraw(
            tokenToWithdraw,
            amountToBeWithdrawn,
            receiverAddress
        );
    }


	/**
	 * @notice 			Function to get uint from the storage
	 *
	 * @param 			key is the name of the key in the storages
	 */
	function getUint(
		string key
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(key));
	}



	/**
	 * @notice 			Setter for all integers we'd like to store
	 *
	 * @param 			key is the key (var name)
	 * @param 			value is the value of integer we'd like to store
	 */
	function setUint(
		string key,
		uint value
	)
	internal
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(key), value);
	}


	/**
	 * @notice 			Getter for moderator earnings per campaign
	 *
	 * @param 			_campaignAddress is the address of the campaign we're searching for moderator earnings
 	 */
	function getModeratorEarningsPerCampaign(
		address _campaignAddress
	)
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorEarningsPerCampaign, _campaignAddress));
	}


	/**
	 * @notice 			Function to return the release date when 2KEY token can be withdrawn from the
	 * 					network
	 */
	function getTwoKeyRewardsReleaseDate()
	external
	view
	returns(uint)
	{
		return getUint(_rewardReleaseAfter);
	}



	/**
	 * @notice			Getter for default moderator percent he takes
 	 */
	function getDefaultIntegratorFeePercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyIntegratorDefaultFeePercent);
	}



	/**
	 * @notice 			Getter for network tax percent which is taken from moderator
	 */
	function getDefaultNetworkTaxPercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyNetworkTaxPercent);
	}


	/**
	 * @notice			Setter in case TwoKeyCongress decides to change the release date
	 */
	function setNewTwoKeyRewardsReleaseDate(
		uint256 newDate
	)
	public
	onlyTwoKeyCongress
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_rewardReleaseAfter),newDate);
	}


	/**
	 * @notice			Setter in case TwoKeyCongress decides to change integrator fee percent
	 */
	function setDefaultIntegratorFeePercent(
		uint newFeePercent
	)
	external
	onlyTwoKeyCongress
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_twoKeyIntegratorDefaultFeePercent),newFeePercent);
	}


	/**
	 * @notice 			Getter to check how many total tokens TwoKeyAdmin received as a moderator from
	 *					various campaign contracts running on 2key.network
	 */
	function getAmountOfTokensReceivedAsModerator()
	public
	view
	returns (uint)
	{
		PROXY_STORAGE_CONTRACT.getUint(keccak256(_rewardsReceivedAsModeratorTotal));
	}


	/**
	 * @notice Free ether is always accepted :)
 	 */
	function()
	external
	payable
	{

	}

}
