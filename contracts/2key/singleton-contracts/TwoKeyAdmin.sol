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

    //Income to ADMIN
    string constant _rewardsReceivedAsModeratorTotal = "rewardsReceivedAsModeratorTotal";
    string constant _moderatorEarningsPerCampaign = "moderatorEarningsPerCampaign";
    string constant _feesFromFeeManagerCollectedInCurrency = "feesFromFeeManagerCollectedInCurrency";
	string constant _feesCollectedFromKyber = "feesCollectedFromKyber";
	string constant _daiCollectedFromUpgradableExchange = "daiCollectedFromUpgradableExchange";
	string constant _feesCollectedFromDistributionRewards = "feesCollectedFromDistributionRewards";


	// Withdrawals from ADMIN
	string constant _amountWithdrawnFromModeratorEarningsPool = "amountWithdrawnFromModeratorEarningsPool";
	string constant _amountWithdrawnFromFeeManagerPoolInCurrency = "amountWithdrawnFromFeeManagerPoolInCurrency";
	string constant _amountWithdrawnFromKyberFeesPool = "amountWithdrawnFromKyberFeesPool";
	string constant _amountWithdrawnFromCollectedDaiFromUpgradableExchange = "amountWithdrawnFromCollectedDaiFromUpgradableExchange";
	string constant _amountWithdrawnFromCollectedDistributionRewards = "amountWithdrawnFromCollectedDistributionRewards";

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
	string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";
	string constant _DAI_TOKEN = "DAI";

	bool initialized = false;


	ITwoKeyAdminStorage public PROXY_STORAGE_CONTRACT; 			//Pointer to storage contract


	/**
	 * @notice 			Modifier which throws if caller is not TwoKeyCongress
	 */
	modifier onlyTwoKeyCongress {
		require(msg.sender == getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyCongress));
	    _;
	}

	modifier onlyTwoKeyBudgetCampaignsPaymentsHandler {
		address twoKeyBudgetCampaignsPaymentsHandler = getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler");
		require(msg.sender == twoKeyBudgetCampaignsPaymentsHandler);
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
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
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
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
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
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
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
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
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
	external
	onlyTwoKeyCongress
	returns (bool)
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		bool completed = IERC20(twoKeyEconomy).transfer(_to, _amount);
		return completed;
	}

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	 *                                                                               *
	 *				ACCOUNTING (BOOKKEEPING) NECESSARY STUFF                         *
	 *                                                                               *
	 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	/**
	 * @notice			Function to update whenever some funds are arriving to TwoKeyAdmin
	 *					from TwoKeyFeeManager contract
	 *
	 * @param			currency is in which currency contract received asset
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


	//	/**
	//	 * @notice			Function to handle and update state every time there's an
	//	 *					income from Kyber network fees
	//	 *
	//	 * @param			amount is the amount contract have received from there
	//	 */
	//	function addFeesCollectedFromKyber(
	//		uint amount
	//	)
	//	internal
	//	{
	//		bytes32 key = keccak256(_feesCollectedFromKyber);
	//		uint feesCollectedFromKyber = PROXY_STORAGE_CONTRACT.getUint(key);
	//		PROXY_STORAGE_CONTRACT.setUint(key, feesCollectedFromKyber.add(amount));
	//	}

	//	/**
	//	 * @notice			Function to withdraw fees collected on Kyber contract to Admin contract
	//	 *
	//	 * @param			reserveContract	is the address of kyber reserve contract for 2KEY token
	//	 * @param			pricingContract is the address of kyber pricing contract for 2KEY token
	//	 */
	//	function withdrawFeesFromKyber(
	//		address reserveContract,
	//		address pricingContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		disableTradeInKyberInternal(reserveContract);
	//		uint availableFees = getKyberAvailableFeesOnReserve(pricingContract);
	//		withdrawTokensFromKyberReserveInternal(
	//			reserveContract,
	//			ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)),
	//			availableFees,
	//			address(this)
	//		);
	//		resetFeesCounterOnKyberContract(pricingContract);
	//		enableTradeInKyberInternal(reserveContract);
	//		addFeesCollectedFromKyber(availableFees);
	//	}


	/**
	 * @notice 			Function to withdraw DAI we have on TwoKeyUpgradableExchange contract
	 *
	 * @param			_amountOfTokens is the amount of the tokens we're willing to withdraw
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function withdrawDAIAvailableToFillReserveFromUpgradableExchange(
		uint _amountOfTokens
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange);
		uint collectedDAI = IUpgradableExchange(twoKeyUpgradableExchange).withdrawDAIAvailableToFill2KEYReserve(_amountOfTokens);

		bytes32 key = keccak256(_daiCollectedFromUpgradableExchange);
		uint _amountWithdrawnCurrently = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, _amountWithdrawnCurrently.add(collectedDAI));
	}

	/**
	 * @notice			Function to withdraw moderator earnings from TwoKeyAdmin contract
	 * 					If 0 is passed as amountToBeWithdrawn, everything available will
	 *					be withdrawn
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens which will be withdrawn
	 */
	function withdrawModeratorEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint moderatorEarningsReceived = getAmountOfTokensReceivedAsModerator();
		uint moderatorEarningsWithdrawn = getAmountOfTokensWithdrawnFromModeratorEarnings();

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = moderatorEarningsReceived.sub(moderatorEarningsWithdrawn);
		} else {
			require(amountToBeWithdrawn <= moderatorEarningsReceived.sub(moderatorEarningsWithdrawn));
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToBeWithdrawn);

		bytes32 keyHash = keccak256(_amountWithdrawnFromModeratorEarningsPool);
		PROXY_STORAGE_CONTRACT.setUint(keyHash, moderatorEarningsWithdrawn.add(amountToBeWithdrawn));
	}

//	function burnModeratorEarnings()
	//TODO: Add function to BURN moderator earnings from Admin (send to 0x0)
	//TODO: For all WITHDRAW funnels if amountToBeWithdrawn = 0 then withdraw/burn everything which is there
	function withdrawFeeManagerEarningsFromAdmin(
		address beneficiary,
		string currency,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{

		uint feeManagerEarningsInCurrency = getAmountCollectedFromFeeManagerInCurrency(currency);
		uint feeManagerEarningsWithdrawn = getAmountWithdrawnFromFeeManagerEarningsInCurrency(currency);

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = feeManagerEarningsInCurrency.sub(feeManagerEarningsWithdrawn);
		} else {
			require(feeManagerEarningsInCurrency.sub(feeManagerEarningsWithdrawn) >= amountToBeWithdrawn);
		}

		if(keccak256(currency) == keccak256("ETH")) {
			beneficiary.transfer(amountToBeWithdrawn);
		} else {
			transferTokens(currency, beneficiary, amountToBeWithdrawn);
		}
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromFeeManagerPoolInCurrency,currency), feeManagerEarningsWithdrawn.add(amountToBeWithdrawn));
	}

	/**
	 * @notice			Function to withdraw earnings collected from Kyber fees from Admin contract
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens to be withdrawn
	 */
	function withdrawKyberFeesEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint kyberTotalReceived = getAmountCollectedFromKyber();
		uint kyberTotalWithdrawn = getAmountWithdrawnFromKyberEarnings();

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = kyberTotalReceived.sub(kyberTotalWithdrawn);
		} else {
			require(amountToBeWithdrawn <= kyberTotalReceived.sub(kyberTotalWithdrawn));
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToBeWithdrawn);

		PROXY_STORAGE_CONTRACT.setUint(
			keccak256(_amountWithdrawnFromKyberFeesPool),
			kyberTotalWithdrawn.add(amountToBeWithdrawn)
		);
	}

	/**
	 * @notice 			Function to withdraw DAI collected from UpgradableExchange from Admin
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens to be withdrawns
	 */
	function withdrawUpgradableExchangeDaiCollectedFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint totalDAICollectedFromPool = getAmountCollectedInDAIFromUpgradableExchange();
		uint totalDAIWithdrawnFromPool = getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings();

		if (amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = totalDAICollectedFromPool.sub(totalDAIWithdrawnFromPool);
		} else {
			require(totalDAIWithdrawnFromPool.add(amountToBeWithdrawn) <= totalDAICollectedFromPool);
		}

		transferTokens(_DAI_TOKEN, beneficiary, amountToBeWithdrawn);

		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromCollectedDaiFromUpgradableExchange), totalDAIWithdrawnFromPool.add(amountToBeWithdrawn));
	}

	function withdrawFeesCollectedFromDistributionRewards(
		address beneficiary,
		uint amountToWithdraw
	)
	public
	onlyTwoKeyCongress
	{
		uint totalFeesCollected = getAmountOfTokensReceivedFromDistributionFees();
		uint totalFeesWithdrawn = getAmountOfTokensWithdrawnFromDistributionFees();

		if (amountToWithdraw == 0) {
			amountToWithdraw = totalFeesCollected.sub(totalFeesWithdrawn);
		} else {
			require(totalFeesWithdrawn.add(amountToWithdraw) <= totalFeesCollected);
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToWithdraw);
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromCollectedDistributionRewards), totalFeesWithdrawn.add(amountToWithdraw));
	}

	/**
	 * @notice			Function for PPC campaigns to update received tokens
	 */
	function updateReceivedTokensAsModeratorPPC(
		uint amountOfTokens,
		address campaignPlasma
	)
	public
	onlyTwoKeyBudgetCampaignsPaymentsHandler
	{
		updateTokensReceivedAsModeratorInternal(amountOfTokens, campaignPlasma);
	}

	/**
	 * @notice			Function to update tokens received from distribution fees
	 * @param			amountOfTokens is the amount of tokens to be sent to admin
	 */
	function updateTokensReceivedFromDistributionFees(
		uint amountOfTokens
	)
	public
	onlyTwoKeyBudgetCampaignsPaymentsHandler
	{
		uint amountCollected = getAmountOfTokensReceivedFromDistributionFees();

        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_feesCollectedFromDistributionRewards),
            amountCollected.add(amountOfTokens)
        );
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
		uint moderatorTokens = updateTokensReceivedAsModeratorInternal(amountOfTokens, msg.sender);
		//Update moderator earnings to campaign
		ITwoKeyCampaign(msg.sender).updateModeratorRewards(moderatorTokens);
	}

	function updateTokensReceivedAsModeratorInternal(
		uint amountOfTokens,
		address campaignAddress
	)
	internal
	returns (uint)
	{
		// Network fee which will be taken from moderator
		uint networkFee = getDefaultNetworkTaxPercent();

		uint moderatorTokens = amountOfTokens.mul(100 - networkFee).div(100);

		bytes32 keyHashTotalRewards = keccak256(_rewardsReceivedAsModeratorTotal);
		PROXY_STORAGE_CONTRACT.setUint(keyHashTotalRewards, moderatorTokens.add((PROXY_STORAGE_CONTRACT.getUint(keyHashTotalRewards))));

		//Emit event through TwoKeyEventSource for the campaign
		ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource)).emitReceivedTokensAsModerator(campaignAddress, moderatorTokens);

		//Now update twoKeyDeepFreezeTokenPool
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		address deepFreezeTokenPool = getAddressFromTwoKeySingletonRegistry("TwoKeyDeepFreezeTokenPool");

		uint tokensForDeepFreezeTokenPool = amountOfTokens.sub(moderatorTokens);

		//Transfer tokens to deep freeze token pool
		transferTokens(_twoKeyEconomy, deepFreezeTokenPool, tokensForDeepFreezeTokenPool);

		//Update contract on receiving tokens
		ITwoKeyDeepFreezeTokenPool(deepFreezeTokenPool).updateReceivedTokensForSuccessfulConversions(tokensForDeepFreezeTokenPool, campaignAddress);

		// Compute the hash for the storage for moderator earnings per campaign
		bytes32 keyHashEarningsPerCampaign = keccak256(_moderatorEarningsPerCampaign, campaignAddress);
		// Take the current earnings
		uint currentEarningsForThisCampaign = PROXY_STORAGE_CONTRACT.getUint(keyHashEarningsPerCampaign);
		// Increase them by earnings added now and store
		PROXY_STORAGE_CONTRACT.setUint(keyHashEarningsPerCampaign, currentEarningsForThisCampaign.add(moderatorTokens));

		return moderatorTokens;
	}


	//    /**
	//     * @notice          Function to call setLiquidityParams on LiquidityConversionRates.sol
	//     *                  contract, it can be called only by TwoKeyAdmin.sol contract
	//     *
	//     * @param           liquidityConversionRatesContractAddress is the address of liquidity conversion rates contract
	//                        the right address depending on environment can be found in configurationFiles/kyberAddresses.json
	//                        It's named "pricing" in the json object
	//     */
	//	function setLiquidityParametersInKyber(
	//        address liquidityConversionRatesContractAddress,
	//        uint _rInFp,
	//        uint _pMinInFp,
	//        uint _numFpBits,
	//        uint _maxCapBuyInWei,
	//        uint _maxCapSellInWei,
	//        uint _feeInBps,
	//        uint _maxTokenToEthRateInPrecision,
	//        uint _minTokenToEthRateInPrecision
	//	)
	//	public
	//	onlyTwoKeyCongress
	//	{
	//        // Call on the contract set liquidity params
	//        IKyberReserveInterface(liquidityConversionRatesContractAddress).setLiquidityParams(
	//            _rInFp,
	//            _pMinInFp,
	//            _numFpBits,
	//            _maxCapBuyInWei,
	//            _maxCapSellInWei,
	//            _feeInBps,
	//            _maxTokenToEthRateInPrecision,
	//            _minTokenToEthRateInPrecision
	//        );
	//	}
	//
	//
	//	/**
	//	 * @notice			Contract to disable trade through Kyber
	//	 *
	//	 * @param			reserveContract is the address of reserve contract
	//	 */
	//	function disableTradeInKyber(
	//		address reserveContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		disableTradeInKyberInternal(reserveContract);
	//	}
	//
	//	function disableTradeInKyberInternal(
	//		address reserveContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(reserveContract).disableTrade();
	//	}
	//
	//
	//	/**
	//	 * @notice			Contract to enable trade through Kyber
	//	 *
	//	 * @param			reserveContract is the address of reserve contract
	//	 */
	//	function enableTradeInKyber(
	//		address reserveContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		enableTradeInKyberInternal(reserveContract);
	//	}
	//
	//	function enableTradeInKyberInternal(
	//		address reserveContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(reserveContract).enableTrade();
	//	}
	//
	//	function getKyberAvailableFeesOnReserve(
	//		address pricingContract
	//	)
	//	internal
	//	view
	//	returns (uint)
	//	{
	//		return IKyberReserveInterface(pricingContract).collectedFeesInTwei();
	//	}
	//
	//
	//	function resetFeesCounterOnKyberContract(
	//		address pricingContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(pricingContract).resetCollectedFees();
	//	}
	//
	//
	//    /**
	//     * @notice          Function to call withdraw on KyberReserve.sol contract
	//     *                  It can be only called by TwoKeyAdmin.sol contract
	//     *
	//     * @param           kyberReserveContractAddress is the address of kyber reserve contract
	//     *                  right address depending on environment can be found in configurationFiles/kyberAddresses.json
	//                        It's named "reserve" in the json object.
	//     */
	//    function withdrawTokensFromKyberReserve(
	//        address kyberReserveContractAddress,
	//        ERC20 tokenToWithdraw,
	//        uint amountToBeWithdrawn,
	//        address receiverAddress
	//    )
	//    external
	//    onlyTwoKeyCongress
	//    {
	//		withdrawTokensFromKyberReserveInternal(
	//			kyberReserveContractAddress,
	//			tokenToWithdraw,
	//			amountToBeWithdrawn,
	//			receiverAddress
	//		);
	//    }

	//	/**
	//	 * @notice			Function to set contracts on Kyber, mostly used to swap from their
	//	 *					staging and production environments
	//	 *
	//	 * @param			kyberReserveContractAddress is our reserve contract address
	//	 * @param			kyberNetworkAddress is the address of kyber network
	//	 * @param			conversionRatesContractAddress is the address of conversion rates contract
	//	 * @param			sanityRatesContractAddress is the address of sanity rates contract
	//	 */
	//	function setContractsKyber(
	//		address kyberReserveContractAddress,
	//		address kyberNetworkAddress,
	//		address conversionRatesContractAddress,
	//		address sanityRatesContractAddress
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		IKyberReserveInterface(kyberReserveContractAddress).setContracts(
	//			kyberNetworkAddress,
	//			conversionRatesContractAddress,
	//			sanityRatesContractAddress
	//		);
	//	}

	//
	//	function withdrawTokensFromKyberReserveInternal(
	//		address kyberReserveContractAddress,
	//		ERC20 tokenToWithdraw,
	//		uint amountToBeWithdrawn,
	//		address receiverAddress
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(kyberReserveContractAddress).withdrawToken(
	//			tokenToWithdraw,
	//			amountToBeWithdrawn,
	//			receiverAddress
	//		);
	//	}


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

	function getAmountOfTokensReceivedFromDistributionFees()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesCollectedFromDistributionRewards));
	}

	function getAmountOfTokensWithdrawnFromDistributionFees()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromCollectedDistributionRewards));
	}

	function getAmountCollectedFromFeeManagerInCurrency(
		string currency
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesFromFeeManagerCollectedInCurrency, currency));
	}

	function getAmountCollectedFromKyber()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesCollectedFromKyber));
	}


	function getAmountCollectedInDAIFromUpgradableExchange()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_daiCollectedFromUpgradableExchange));
	}


	function getAmountOfTokensWithdrawnFromModeratorEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromModeratorEarningsPool));
	}

	function getAmountWithdrawnFromFeeManagerEarningsInCurrency(
		string currency
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromFeeManagerPoolInCurrency,currency));
	}

	function getAmountWithdrawnFromKyberEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromKyberFeesPool));
	}

	function getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromCollectedDaiFromUpgradableExchange));
	}

	function transferTokens(
		string token,
		address beneficiary,
		uint amount
	)
	internal
	{
		IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(token)).transfer(
			beneficiary,
			amount
		);
	}

	function getAccountingReport()
	public
	view
	returns (bytes)
	{
		return (
			abi.encodePacked(
				getAmountOfTokensReceivedAsModerator(),
				getAmountCollectedFromFeeManagerInCurrency("DAI"),
				getAmountCollectedFromFeeManagerInCurrency("ETH"),
				getAmountCollectedFromFeeManagerInCurrency("2KEY"),
				getAmountCollectedFromKyber(),
				getAmountCollectedInDAIFromUpgradableExchange(),
				getAmountOfTokensReceivedFromDistributionFees(),
				getAmountOfTokensWithdrawnFromModeratorEarnings(),
				getAmountWithdrawnFromKyberEarnings(),
				getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings(),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("DAI"),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("ETH"),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("2KEY"),
				getAmountOfTokensWithdrawnFromDistributionFees()
			)
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
