pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryStorage.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";
import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";

import "../libraries/SafeMath.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventory contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventory is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryStorage PROXY_STORAGE_CONTRACT;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";
    string constant _twoKeyCPCCampaignPlasma = "TwoKeyCPCCampaignPlasma";

    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2LeftOverForContractor = "campaignPlasma2LeftOvrForContractor";
    string constant _campaignPlasma2ReferrerRewardsTotal = "campaignPlasma2ReferrerRewardsTotal";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2initialRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2amountOfStableCoins = "campaignPlasma2amountOfStableCoins";
    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";   // msg.sender

    string constant _2KEYBalance = "2KEYBalance";
    string constant _USDBalance = "USDBalance";

    /**
     * @notice Function for contract initialization
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaCampaignsInventoryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice      Modifier which will be used to restrict set function calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }

    /**
     * @notice      Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }

    /**
     * @notice          Function that allocates specified amount of 2KEY from users balance to this contract's balance
     * @notice          Function can be called only once
     */
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Check if user has already called this function before, if so he can not call it second time
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)) == address(0)
        );
        // Get pair rate from ITwoKeyPlasmaExchangeRate contract
        uint rate = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate))
        .getPairValue("2KEY-USD");
        // Calculate the bountyPerConversion2KEY value
        uint bountyPerConversion2KEY = bountyPerConversionUSD.mul(10**18).div(rate);

        // Set contractor user
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor), msg.sender);
        // Set initial 2Key budget
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialBudget2Key), amount);
        // Set current value pair rate for 2KEY-USD
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate), rate);
        // Set 2Key bounty per conversion value
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY), bountyPerConversion2KEY);
        // Set starting rebalancing ratio
        //TODO: 1 = 10**18, since it's decimal number afterwards --> change 1 -> 10**18
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio), 1);
        // Set true value for 2Key directly budgeting
        PROXY_STORAGE_CONTRACT.setBool(keccak256(campaignAddressPlasma, _campaignPlasma2isBudgetedWith2KeyDirectly), true);

        // Perform direct 2Key transfer
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
            .transfer2KEYFrom(msg.sender, amount);

        // Initialize CPC campaign plasma interface
        ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
        .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, true);
    }

    /**
     * @notice          Function that allocates specified amount of USDT from users balance to this contract's balance
     * @notice          Function can be called only once
     */
    function addInventoryUSDT(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Check if user has already called this function before, if so he can not call it second time
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)) == address(0)
        );
        // Get pair rate from ITwoKeyPlasmaExchangeRate contract
        uint rate = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate))
        .getPairValue("2KEY-USD");
        // Calculate the bountyPerConversion2KEY value
        uint bountyPerConversion2KEY = bountyPerConversionUSD.mul(10**18).div(rate);

        // Set contractor user
        PROXY_STORAGE_CONTRACT.setAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor), msg.sender);
        // Set amount of Stable coins
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2amountOfStableCoins), amount);
        // Set current rate for 2KEY-USD value pair
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate), rate);
        // Set current bountyPerConversion2KEY
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY), bountyPerConversion2KEY);
        // Set starting rebalancing ratio
        //TODO: 1 = 10**18, since it's decimal number afterwards --> change 1 -> 10**18
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio), 1);

        // Perform a transfer
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
        .transferUSDTFrom(msg.sender, amount);

        // Set initial parameters and validates campaign
        ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
        .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, false);
    }

    /**
     * @notice      Function that returns all information about given campaign
     * @param       campaignAddressPlasma is address of the campaign
     */
    function getCampaignInformation(
        address campaignAddressPlasma
    )
    public
    view
    returns(
        address,
        uint,
        uint,
        uint,
        uint,
        uint,
        bool
    )
    {
        return(
            // Gets campaigns contractor
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(campaignAddressPlasma, _campaignPlasma2Contractor)),
            // Gets campaigns initial 2KEY budget
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialBudget2Key)),
            // Gets campaigns amount of Stable coins
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2amountOfStableCoins)),
            // Gets the initial rate
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2initialRate)),
            // Gets bounty per conversion in 2KEY
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2bountyPerConversion2KEY)),
            // Gets rebalancing ratio (default value is 1)
            PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignAddressPlasma, _campaignPlasma2rebalancingRatio)),
            // Gets boolean value if campaign is budgeted directly with 2Key currency
            PROXY_STORAGE_CONTRACT.getBool(keccak256(campaignAddressPlasma, _campaignPlasma2isBudgetedWith2KeyDirectly))
        );
    }

    /**
     * @notice          Function to end selected budget campaign by maintainer, and perform
     *                  actions regarding rebalancing, reserving tokens, and distributing
     *                  moderator earnings, as well as calculating leftover for contractor
     *
     * @param           campaignPlasma is the plasma address of the campaign
     * @param           totalAmountForReferrerRewards is the total amount before rebalancing referrers earned
     * @param           totalAmountForModeratorRewards is the total amount moderator earned before rebalancing
     */
    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    public
    onlyMaintainer
    {
        // Check if campaign has not ended yet
        require(PROXY_STORAGE_CONTRACT.getBool(keccak256(campaignPlasma, _campaignPlasma2isCampaignEnded)) == false);
        // Setting bool that campaign is over now
        PROXY_STORAGE_CONTRACT.setBool(keccak256(campaignPlasma, _campaignPlasma2isCampaignEnded), true);

        // Get how many tokens were inserted at the beginning
        uint initialBountyForCampaign = PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignPlasma, _campaignPlasma2initialBudget2Key));
        // Rebalancing everything except referrer rewards
        uint amountToRebalance = initialBountyForCampaign.sub(totalAmountForReferrerRewards);
        // Amount after rebalancing is initially amount to rebalance
        uint amountAfterRebalancing = amountToRebalance;
        // Initially rebalanced moderator rewards are total moderator rewards
        uint rebalancedModeratorRewards = totalAmountForModeratorRewards;
        // Initial ratio is 1
        uint rebalancingRatio = 10**18;

        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(campaignPlasma, _campaignPlasma2isBudgetedWith2KeyDirectly)) == false) {
            // If budget added as stable coin we do rebalancing
            (amountAfterRebalancing, rebalancingRatio)
            = rebalanceRates(
                PROXY_STORAGE_CONTRACT.getUint(keccak256(campaignPlasma, _campaignPlasma2initialRate)),
                amountToRebalance
            );

            rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);
        }

        uint leftoverForContractor = amountAfterRebalancing.sub(rebalancedModeratorRewards);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Set total amount to use for referrers
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignPlasma, _campaignPlasma2ReferrerRewardsTotal), totalAmountForReferrerRewards);
        // Leftover for contractor
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignPlasma, _campaignPlasma2LeftOverForContractor), leftoverForContractor);
        // Set rebalancing ratio for campaign
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignPlasma, _campaignPlasma2rebalancingRatio), rebalancingRatio);

        // Emit an event to checksum all the balances per campaign
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"))
            .emitEndedBudgetCampaign(
                campaignPlasma,
                leftoverForContractor,
                rebalancedModeratorRewards
            );

    }


    /**
     * @notice      Function to rebalance the rates
     *
     * @param       initial2KEYRate is 2KEY rate at the moment of campaign starting
     * @param       amountOfTokensToRebalance is number of tokens left
     */
    function rebalanceRates(
        uint initial2KEYRate,
        uint amountOfTokensToRebalance
    )
    internal
    returns
    (uint, uint)
    {
        // Load twoKeyEconomy address
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        // Load twoKeyUpgradableExchange address
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Take the current usd to 2KEY rate against we're rebalancing contractor leftover and moderator rewards
        uint usd2KEYRateWeiNow = IUpgradableExchange(twoKeyUpgradableExchange).sellRate2key();

        // Ratio is initial rate divided by new rate, so if rate went up, this will be less than 1
        uint rebalancingRatio = initial2KEYRate.mul(10**18).div(usd2KEYRateWeiNow);

        // Calculate new rebalanced amount of tokens
        uint rebalancedAmount = amountOfTokensToRebalance.mul(rebalancingRatio).div(10**18);

        // If price went up, leads to ratio is going to be less than 10**18
        if(rebalancingRatio < 10**18) {
            // Calculate how much tokens should be given back to exchange
            uint tokensToGiveBackToExchange = amountOfTokensToRebalance.sub(rebalancedAmount);
            // Approve upgradable exchange to take leftover back
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, tokensToGiveBackToExchange);
            // Call the function to release all DAI for this contract to reserve and to take approved amount of 2key back to liquidity pool
            IUpgradableExchange(twoKeyUpgradableExchange).returnTokensBackToExchangeV1(tokensToGiveBackToExchange);
        }
        // Otherwise we assume that price went down, which leads that ratio will be greater than 10**18
        else  {
            uint tokensToTakeFromExchange = rebalancedAmount.sub(amountOfTokensToRebalance);
            // Get more tokens we need
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancingV1(tokensToTakeFromExchange);
        }
        // Return new rebalanced amount as well as ratio against which rebalancing was done.
        return (rebalancedAmount, rebalancingRatio);
    }


    /**
     * @notice          Function to set how many tokens are being distributed to moderator
     *                  as well as distribute them.
     * @param           campaignPlasma is the plasma address of selected campaign
     * @param           rebalancedModeratorRewards is the amount for moderator after rebalancing
     */
    function setAndDistributeModeratorEarnings(
        address campaignPlasma,
        uint rebalancedModeratorRewards
    )
    internal
    {
        // Account amount moderator earned on this campaign
        PROXY_STORAGE_CONTRACT.setUint(keccak256(campaignPlasma, _campaignPlasma2ModeratorEarnings), rebalancedModeratorRewards);

        // Get twoKeyAdmin address
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Transfer 2KEY tokens to moderator
        transfer2KEY(
            twoKeyAdmin,
            rebalancedModeratorRewards
        );

        // Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
        ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModeratorPPC(rebalancedModeratorRewards, campaignPlasma);
    }


    /**
     * @notice 			Function to transfer 2KEY tokens
     *
     * @param			receiver is the address of tokens receiver
     * @param			amount is the amount of tokens to be transfered
     */
    function transfer2KEY(
        address receiver,
        uint amount
    )
    internal
    {
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transfer(
            receiver,
            amount
        );
    }
}
