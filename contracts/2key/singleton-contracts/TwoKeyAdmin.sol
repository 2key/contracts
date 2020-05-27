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
import "../interfaces/IKyberReserveInterface.sol";
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

	/**
	 * Accounting necessary stuff
	 */
	string constant _rewardsReceivedAsModeratorTotal = "rewardsReceivedAsModeratorTotal";
	string constant _moderatorEarningsPerCampaign = "moderatorEarningsPerCampaign";
	string constant _feesFromFeeManagerCollectedInCurrency = "feesFromFeeManagerCollectedInCurrency";
	string constant _feesCollectedFromKyber = "feesCollectedFromKyber";
	string constant _daiCollectedFromUpgradableExchange = "daiCollectedFromUpgradableExchange";

	//TODO: Add everything same for withdrawal from admin
	string constant _amountWithdrawnFromModeratorEarningsPool = "amountWithdrawnFromModeratorEarningsPool";
	string constant _amountWithdrawnFromFeeManagerPoolInCurrency = "amountWithdrawnFromFeeManagerPoolInCurrency";
	string constant _amountWithdrawnFromKyberFeesPool = "amountWithdrawnFromKyberFeesPool";
	string constant _daiCollectedFromUpgradableExchange ="daiCollectedFromUpgradableExchange";

	/**
	 * Keys for the addresses we're accessing
	 */
	string constant _twoKeyCongress = "TwoKeyCongress";
	string constant _twoKeyUpgradableExchange = "TwoKeyUpgradableExchange";
	string constant _twoKeyRegistry = "TwoKeyRegistry";
	string constant _twoKeyEconomy = "TwoKeyEconomy";
	string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
	string constant _twoKeyEventSource = "TwoKeyEventSource";
	string constant _twoKeyFeeManager = "TwoKeyFeeManager";



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
	 * @notice			Modifier which throws if the contract sending request is not
	 *					TwoKeyFeeManager contract
	 */
	modifier onlyTwoKeyFeeManager {
		require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFeeManager));
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
	 * @notice 			Function to migrate current Fee manager state and funds to admin and update
	 * 					state variables
	 * @param			_dai is the address on DAI token (argument due to blockchain env)
	 */
	function migrateCurrentFeeManagerStateToAdminAndWithdrawFunds(
		address _dai
	)
	public
	onlyTwoKeyCongress
	{
		address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
		uint collectedETH = ITwoKeyFeeManager(twoKeyFeeManager).withdrawEtherCollected();
		uint collected2KEY = ITwoKeyFeeManager(twoKeyFeeManager).withdraw2KEYCollected();
		uint collectedDAI = ITwoKeyFeeManager(twoKeyFeeManager).withdrawDAICollected(_dai);

		bytes32 key1 = keccak256(_feesFromFeeManagerCollectedInCurrency, "ETH");
		uint feesCollectedFromFeeManagerInCurrencyETH = PROXY_STORAGE_CONTRACT.getUint(key1);
		PROXY_STORAGE_CONTRACT.setUint(key1, feesCollectedFromFeeManagerInCurrencyETH.add(collectedETH));


		bytes32 key2 = keccak256(_feesFromFeeManagerCollectedInCurrency, "2KEY");
		uint feesCollectedFromFeeManagerInCurrency2KEY = PROXY_STORAGE_CONTRACT.getUint(key2);
		PROXY_STORAGE_CONTRACT.setUint(key2, feesCollectedFromFeeManagerInCurrency2KEY.add(collected2KEY));

		bytes32 key3 = keccak256(_feesFromFeeManagerCollectedInCurrency, "DAI");
		uint feesCollectedFromFeeManagerInCurrencyDAI = PROXY_STORAGE_CONTRACT.getUint(key3);
		PROXY_STORAGE_CONTRACT.setUint(key3, feesCollectedFromFeeManagerInCurrencyDAI.add(collectedDAI));
	}


	/**
	 * @notice			Function to update whenever some funds are arriving to TwoKeyAdmin
	 *
	 * @param			currency is in which currency we received money
	 * @param			amount is the amount which is received
	 */
	function addFeesCollectedInCurrency(
		string currency,
		uint amount
	)
	public
	payable
	onlyTwoKeyFeeManager
	{
		bytes32 key = keccak256(_feesFromFeeManagerCollectedInCurrency, currency);
		uint feesCollectedFromFeeManagerInCurrency = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, feesCollectedFromFeeManagerInCurrency.add(amount));
	}


	function addFeesCollectedFromKyber(
		uint amount
	)
	internal
	{
		bytes32 key = keccak256(_feesCollectedFromKyber);
		uint feesCollectedFromKyber = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, feesCollectedFromKyber.add(amount));
	}


	function withdrawFeesFromKyber()
	public
	onlyTwoKeyCongress
	{
		//TODO: Disable trade
		//TODO: get available fees
		//TODO: withdraw 98% of available fees
		//TODO: Reset counters for available fees to 0
		//TODO: Re-enable trade on kyber
		uint amount = 0; //TODO: Add interface for kyber interaction
		addFeesCollectedFromKyber(amount);
	}

	/**
	 * @notice 			Function to withdraw any ERC20 we have on TwoKeyUpgradableExchange contract
	 *
	 * @param			_amountOfTokens is the amount of the tokens we're willing to withdraw
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function withdrawDAIAvailableToFillReserveFromUpgradableExchange(
		uint _amountOfTokens
	)
	public
	onlyTwoKeyCongress
	{
		address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange);
		uint collectedDAI = IUpgradableExchange(twoKeyUpgradableExchange).withdrawDAIAvailableToFill2KEYReserve(_amountOfTokens);

		bytes32 key = keccak256(_daiCollectedFromUpgradableExchange);
		uint _amountWithdrawnCurrently = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, _amountWithdrawnCurrently.add(collectedDAI));
	}


	function withdrawModeratorEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint moderatorEarningsReceived = getAmountOfTokensReceivedAsModerator();
		uint moderatorEarningsWithdrawn = getAmountOfTokensWithdrawnFromModeratorEarnings();

		require(amountToBeWithdrawn <= moderatorEarningsReceived.sub(moderatorEarningsWithdrawn));
		IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)).transfer(
			beneficiary,
			amountToBeWithdrawn
		);
		//TODO: Add events
	}

	function withdrawFeeManagerEarningsFromAdmin(
		address beneficiary,
		string currency,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		//TODO: Add events
	}

	function withdrawKyberFeesEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		//TODO: Add events
	}

	function withdrawUpgradableExchangeDaiCollectedFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		//TODO: Add events
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
	 * @notice			Function to swap some DAI tokens from Upgradable exchange for 2KEY
	 *
	 * @param			daiAmountToBeExchanged of DAI tokens to be exchanged for 2KEY tokens
	 */
	function exchangeAvailableDAIFor2KEYThroughKyber(
		uint daiAmountToBeExchanged,
		uint minApprovedConversionRate
	)
	public
	onlyTwoKeyCongress
	{
		IUpgradableExchange(getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange)).swapDaiAvailableToFillReserveFor2KEY(
			daiAmountToBeExchanged,
			minApprovedConversionRate
		);
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
        IKyberReserveInterface(liquidityConversionRatesContractAddress).setLiquidityParams(
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
	 * @notice			Contract to disable trade through Kyber
	 *
	 * @param			reserveContract is the address of reserve contract
	 */
	function disableTradeInKyber(
		address reserveContract
	)
	public
	onlyTwoKeyCongress
	{
		IKyberReserveInterface(reserveContract).disableTrade();
	}


	/**
	 * @notice			Contract to enable trade through Kyber
	 *
	 * @param			reserveContract is the address of reserve contract
	 */
	function enableTradeInKyber(
		address reserveContract
	)
	public
	onlyTwoKeyCongress
	{
		IKyberReserveInterface(reserveContract).enableTrade();
	}


	/**
	 * @notice			Function to set contracts on Kyber, mostly used to swap from their
	 *					staging and production environments
	 *
	 * @param			kyberReserveContractAddress is our reserve contract address
	 * @param			kyberNetworkAddress is the address of kyber network
	 * @param			conversionRatesContractAddress is the address of conversion rates contract
	 * @param			sanityRatesContractAddress is the address of sanity rates contract
	 */
	function setContractsKyber(
		address kyberReserveContractAddress,
		address kyberNetworkAddress,
		address conversionRatesContractAddress,
		address sanityRatesContractAddress
	)
	public
	onlyTwoKeyCongress
	{
		IKyberReserveInterface(kyberReserveContractAddress).setContracts(
			kyberNetworkAddress,
			conversionRatesContractAddress,
			sanityRatesContractAddress
		);
	}


    /**
     * @notice          Function to call withdraw on KyberReserve.sol contract
     *                  It can be only called by TwoKeyAdmin.sol contract
     *
     * @param           kyberReserveContractAddress is the address of kyber reserve contract
     *                  right address depending on environment can be found in configurationFiles/kyberAddresses.json
                        It's named "reserve" in the json object.
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
        IKyberReserveInterface(kyberReserveContractAddress).withdrawToken(
            tokenToWithdraw,
            amountToBeWithdrawn,
            receiverAddress
        );
    }

	/**
	 * @notice			Function to withdraw ether from Kyber reserve
	 *
	 * @param			kyberReserveContractAddress is the address of reserve
	 * @param			amountOfEth is the amount of Ether to be withdrawn, in WEI
	 */
	function withdrawEtherFromKyberReserve(
		address kyberReserveContractAddress,
		uint amountOfEth
	)
	public
	onlyTwoKeyCongress
	{
		IKyberReserveInterface(kyberReserveContractAddress).withdrawEther(
			amountOfEth,
			address(this)
		);
	}

	function setKyberReserveContractAddressOnUpgradableExchange(
		address kyberReserveContractAddress
	)
	public
	onlyTwoKeyCongress
	{
		IUpgradableExchange(getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange)).setKyberReserveInterfaceContractAddress(
			kyberReserveContractAddress
		);
	}

	function setNewSpreadWei(
		uint newSpreadWei
	)
	public
	onlyTwoKeyCongress
	{
		IUpgradableExchange(getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange)).setSpreadWei(
			newSpreadWei
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
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_rewardsReceivedAsModeratorTotal));
	}

	function getAmountOfTokensWithdrawnFromModeratorEarnings()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromModeratorEarningsPool));
	}

	function getAmountReceivedFromFeeManagerInCurrency(
		string currency
	)
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesFromFeeManagerCollectedInCurrency,currency));
	}

	function getAmountWithdrawnFromFeeManagerEarningsInCurrency(
		string currency
	)
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromFeeManagerPoolInCurrency,currency));
	}

	function getAmountReceivedFromKyber()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesCollectedFromKyber));
	}

	function getAmountWithdrawnFromKyberEarnings()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromKyberFeesPool));
	}


	function getAccountingReport()
	public
	view
	returns (uint,uint,uint,uint,uint,uint)
	{
		uint amountReceivedAsModerator = getAmountOfTokensReceivedAsModerator();

		uint amountReceivedFromFeeManagerAsDAI = getAmountReceivedFromFeeManagerInCurrency("DAI");
		uint amountReceivedFromFeeManagerAsETH = getAmountReceivedFromFeeManagerInCurrency("ETH");
		uint amountReceivedFromFeeManagerAs2KEY = getAmountReceivedFromFeeManagerInCurrency("2KEY");

		uint amountReceivedFromKyber = getAmountReceivedFromKyber();

		uint amountOfDAIWithdrawnFromUpgradableExchange = PROXY_STORAGE_CONTRACT.getUint(keccak256(_daiCollectedFromUpgradableExchange));

		return (
			amountReceivedAsModerator,
			amountReceivedFromFeeManagerAsDAI,
			amountReceivedFromFeeManagerAsETH,
			amountReceivedFromFeeManagerAs2KEY,
			amountReceivedFromKyber,
			amountOfDAIWithdrawnFromUpgradableExchange
		);
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
