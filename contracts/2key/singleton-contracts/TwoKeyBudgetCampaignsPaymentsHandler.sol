pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/ITether.sol";
import "../interfaces/storage-contracts/ITwoKeyBudgetCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../libraries/SafeMath.sol";

contract TwoKeyBudgetCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    /**
     * State variables
     * TO BE EXPANDED
     */

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2contractor = "campaignPlasma2contractor";

    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2StableCoinAddress = "campaignPlasma2StableCoinAddress";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2initialRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2amountOfStableCoins = "campaignPlasma2amountOfStableCoins";
    string constant _numberOfDistributionCycles = "numberOfDistributionCycles";
    string constant _distributionCycleToTotalDistributed = "_distributionCycleToTotalDistributed";
    string constant _campaignPlasma2ReferrerRewardsTotal = "campaignPlasma2ReferrerRewardsTotal";
    string constant _campaignPlasmaToModeratorEarnings = "campaignPlasmaToModeratorEarnings";
    string constant _campaignPlasmaToLeftOverForContractor = "campaignPlasmaToLeftOverForContractor";
    string constant _campaignPlasmaToLeftoverWithdrawnByContractor = "campaignPlasmaToLeftoverWithdrawnByContractor";
    string constant _feePerCycleIdPerReferrer = "feePerCycleIdPerReferrer";

    ITwoKeyBudgetCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorageContract
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBudgetCampaignsPaymentsHandlerStorage(_proxyStorageContract);

        initialized = true;
    }

    /**
     * ------------------------------------
     *          Contractor actions
     * ------------------------------------
     */

    /**
     * @notice          Function which will be used in order to add inventory for campaign
     *                  directly with 2KEY tokens. In order to make this
     *                  transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOf2KEYTokens is the amount of 2KEY tokens user adds to budget
     */
    function addInventory2KEY(
        address campaignPlasma,
        uint amountOf2KEYTokens,
        uint bountyPerConversionFiat
    )
    public
    {
        // Require that budget is not previously set and assign amount of 2KEY tokens
        requireBudgetNotSetAndSetBudget(campaignPlasma, amountOf2KEYTokens);
        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        // Get 2KEY sell rate at the moment
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // calculate bounty per conversion 2KEY
        uint bountyPerConversion2KEY = bountyPerConversionFiat.mul(10**18).div(rate);

        // Calculate and set bounty per conversion in 2KEY units
        setUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma),
            bountyPerConversion2KEY
        );

        // Set rate at which 2KEY is put to campaign
        setUint(
            keccak256(_campaignPlasma2initialRate, campaignPlasma),
            rate
        );

        // Set that campaign is budgeted directly with 2KEY tokens
        setBool(
            keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma),
            true
        );

        // Take 2KEY tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOf2KEYTokens
        );
    }

    /**
     * @notice          Function which will be used in order to add inventory for campaign
     *                  directly with stable coin tokens. In order to make this
     *                  transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOfStableCoins is the amount of stable coins user adds to budget
     * @param           tokenAddress is stableCoinAddress
     */
    function addInventory(
        address campaignPlasma,
        uint amountOfStableCoins,
        uint bountyPerConversionFiat,
        address tokenAddress
    )
    public
    {
        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");

        // Handle case for Tether due to different ERC20 interface it has
        if (tokenAddress == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDT")) {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            ITether(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfStableCoins
            );
        } else {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfStableCoins
            );
        }


        uint totalTokensBought;
        uint tokenPrice;

        // Buy tokens
        (totalTokensBought, tokenPrice) = IUpgradableExchange(twoKeyUpgradableExchange).buyTokensWithERC20(amountOfStableCoins, tokenAddress);

        // Calculate and set bounty per conversion in 2KEY units
        uint bountyPerConversion2KEY = bountyPerConversionFiat.mul(10 ** 18).div(tokenPrice);

        // Require that budget is not previously set and set initial budget to amount of 2KEY tokens
        requireBudgetNotSetAndSetBudget(campaignPlasma, totalTokensBought);

        // SSTORE 20k gas * 3 = 60k 3x uint ==> 256 bytes * 3 * 8 =  6144 gas
        // 375 gas + 5 gas for each byte
        // 10%   60000 - 6144 = 53856 saving

        setUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma),
            bountyPerConversion2KEY
        );

        setUint(
            keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma),
            amountOfStableCoins
        );

        // Set stable coin which is used to budget campaign
        setAddress(
            keccak256(_campaignPlasma2StableCoinAddress, campaignPlasma),
            tokenAddress
        );

        // Set the rate at which we have bought 2KEY tokens
        setUint(
            keccak256(_campaignPlasma2initialRate, campaignPlasma),
            tokenPrice
        );
    }


    /**
     * @notice          Function where contractor can withdraw if there's any leftover on his campaign
     * @param           campaignPlasmaAddress is plasma address of campaign
     */
    function withdrawLeftoverForContractor(
        address campaignPlasmaAddress
    )
    public
    {
        // Require that this function is possible to call only by contractor
        require(
            getAddress(keccak256(_campaignPlasma2contractor,campaignPlasmaAddress)) == msg.sender
        );

        // Get the leftover for contractor
        uint leftoverForContractor = getUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasmaAddress)
        );

        // Check that he has some leftover which can be zero in case that campaign is not ended yet
        require(leftoverForContractor > 0);

        // Generate key if contractor have withdrawn his leftover for specific campaign
        bytes32 key = keccak256(_campaignPlasmaToLeftoverWithdrawnByContractor, campaignPlasmaAddress);

        // Require that he didn't withdraw it
        require(getBool(key) == false);

        // State that now he has withdrawn the tokens.
        setBool(key, true);

        transfer2KEY(
            msg.sender,
            leftoverForContractor
        );
    }


    /**
     * ------------------------------------
     *          Maintainer actions
     * ------------------------------------
     */

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
        // Generate key for storage variable isCampaignEnded
        bytes32 keyIsCampaignEnded = keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma);

        // Require that campaign is not ended yet
        require(getBool(keyIsCampaignEnded) == false);

        // End campaign
        setBool(keyIsCampaignEnded, true);

        // Get how many tokens were inserted at the beginning
        uint initialBountyForCampaign = getInitialBountyForCampaign(campaignPlasma);

        // Rebalancing everything except referrer rewards
        uint amountToRebalance = initialBountyForCampaign.sub(totalAmountForReferrerRewards);

        // Amount after rebalancing is initially amount to rebalance
        uint amountAfterRebalancing = amountToRebalance;

        // Initially rebalanced moderator rewards are total moderator rewards
        uint rebalancedModeratorRewards = totalAmountForModeratorRewards;

        // Initial ratio is 1
        uint rebalancingRatio = 10**18;

        if(getIsCampaignBudgetedDirectlyWith2KEY(campaignPlasma) == false) {
            // If budget added as stable coin we do rebalancing
            (amountAfterRebalancing, rebalancingRatio)
                = rebalanceRates(
                    getInitial2KEYRateForCampaign(campaignPlasma),
                    amountToRebalance
            );

            rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);
        }

        uint leftoverForContractor = amountAfterRebalancing.sub(rebalancedModeratorRewards);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Set total amount to use for referrers
        setUint(
            keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma),
            totalAmountForReferrerRewards
        );

        // Leftover for contractor
        setUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasma),
            leftoverForContractor
        );

        // Set rebalancing ratio for campaign
        setRebalancingRatioForCampaign(campaignPlasma, rebalancingRatio);

        // Emit an event to checksum all the balances per campaign
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"))
            .emitEndedBudgetCampaign(
                campaignPlasma,
                leftoverForContractor,
                rebalancedModeratorRewards
            );
    }


    /**
     * @notice          Function to distribute rewards between influencers, increment global cycle id,
     *                  and update how much rewards are ever being distributed from this contract
     *
     * @param           influencers is the array of influencers
     * @param           balances is the array of corresponding balances for the influencers above
     *
     */
    function pushAndDistributeRewardsBetweenInfluencers(
        address [] influencers,
        uint [] balances,
        uint nonRebalancedTotalPayout,
        uint rebalancedTotalPayout,
        uint cycleId,
        uint feePerReferrerIn2KEY
    )
    public
    onlyMaintainer
    {
        // Get the address of 2KEY token
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        // Get the address of twoKeyUpgradableExchange contract
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Total distributed in cycle
        uint totalDistributed;
        // Iterator
        uint i;

        uint difference;
        // Leads to we need to return some tokens back to Upgradable Exchange
        if(nonRebalancedTotalPayout > rebalancedTotalPayout) {
            difference = nonRebalancedTotalPayout.sub(rebalancedTotalPayout);
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, difference);
            IUpgradableExchange(twoKeyUpgradableExchange).returnTokensBackToExchangeV1(difference);
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitRebalancedRewards(
                cycleId,
                difference,
                "RETURN_TOKENS_TO_EXCHANGE"
            );
        } else if (nonRebalancedTotalPayout < rebalancedTotalPayout) {
            // Leads to we need to get more tokens from Upgradable Exchange
            difference = rebalancedTotalPayout.sub(nonRebalancedTotalPayout);
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancingV1(difference);
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitRebalancedRewards(
                cycleId,
                difference,
                "GET_TOKENS_FROM_EXCHANGE"
            );
        }

        uint numberOfReferrers = influencers.length;

        // Iterate through all influencers, distribute them rewards, and account amount received per cycle id
        for (i = 0; i < numberOfReferrers; i++) {
            // Require that referrer earned more than fees
            require(balances[i] > feePerReferrerIn2KEY);
            // Sub fee per referrer from balance to pay
            uint balance = balances[i].sub(feePerReferrerIn2KEY);
            // Transfer required tokens to influencer
            IERC20(twoKeyEconomy).transfer(influencers[i], balance);
            // Sum up to totalDistributed to referrers
            totalDistributed = totalDistributed.add(balance);
        }


        transferFeesToAdmin(feePerReferrerIn2KEY, numberOfReferrers, twoKeyEconomy);


        // Set how much is total distributed per distribution cycle
        setUint(
            keccak256(_distributionCycleToTotalDistributed, cycleId),
            totalDistributed
        );
    }


    /**
     * ------------------------------------------------
     *        Internal functions performing logic operations
     * ------------------------------------------------
     */

    /**
     * @notice          Function to transfer fees taken from referrer rewards to admin contract
     * @param           feePerReferrer is fee taken per referrer equaling 0.5$ in 2KEY at the moment
     * @param           numberOfReferrers is number of referrers being rewarded in this cycle
     * @param           twoKeyEconomy is 2KEY token contract
     */
    function transferFeesToAdmin(
        uint feePerReferrer,
        uint numberOfReferrers,
        address twoKeyEconomy
    )
    internal
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        IERC20(twoKeyEconomy).transfer(
            twoKeyAdmin,
            feePerReferrer.mul(numberOfReferrers)
        );

        // Update in admin tokens receiving from fees
        ITwoKeyAdmin(twoKeyAdmin).updateTokensReceivedFromDistributionFees(feePerReferrer.mul(numberOfReferrers));
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
        setUint(
            keccak256(_campaignPlasmaToModeratorEarnings, campaignPlasma),
            rebalancedModeratorRewards
        );

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
     * @notice          Function to require that initial budget is not set, which
     *                  will prevent any way of adding inventory to specific campaigns
     *                  after it's first time added
     * @param           campaignPlasma is campaign plasma address
     */
    function requireBudgetNotSetAndSetBudget(
        address campaignPlasma,
        uint amount2KEYTokens
    )
    internal
    {

        bytes32 keyHashForInitialBudget = keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma);
        // Require that initial budget is not being added, since it can be done only once.
        require(getUint(keyHashForInitialBudget) == 0);
        // Set initial budget added
        setUint(keyHashForInitialBudget, amount2KEYTokens);
    }

    function rebalanceRates(
        uint initial2KEYRate,
        uint amountOfTokensToRebalance
    )
    internal
    returns (uint,uint)
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
     * ------------------------------------------------
     *        Internal getters and setters
     * ------------------------------------------------
     */

    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key,value);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }

    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key,value);
    }

    function equals(
        string a,
        string b
    )
    internal
    pure
    returns (bool) {
        return keccak256(a) == keccak256(b) ? true : false;
    }


    /**
     * @notice          Function whenever called, will increment number of distribution cycles
     */
    function incrementNumberOfDistributionCycles()
    internal
    {
        bytes32 key = keccak256(_numberOfDistributionCycles);
        setUint(key,getUint(key) + 1);
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

    /**
     * @notice          Internal setter function to store how much stable coins were
     *                  added to fund this campaign
     * @param           campaignPlasma is plasma campaign address
     * @param           amountOfStableCoins is the amount used for campaign funding
     */
    function setAmountOfStableCoinsUsedToFundCampaign(
        address campaignPlasma,
        uint amountOfStableCoins
    )
    internal
    {
        setUint(
            keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma),
            amountOfStableCoins
        );
    }

    function setRebalancingRatioForCampaign(
        address campaignPlasma,
        uint rebalancingRatio
    )
    internal
    {
        setUint(
            keccak256(_campaignPlasma2rebalancingRatio, campaignPlasma),
            rebalancingRatio
        );
    }


    /**
     * ------------------------------------------------
     *              Public getters
     * ------------------------------------------------
     */

    /**
     * @notice          Function to return rebalancing ratio for specific campaign,
     *                  in case campaign was funded with 2KEY will return 1 ETH as neutral
     * @param           campaignPlasma is plasma campaign address
     */
    function getRebalancingRatioForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        uint ratio = getUint(keccak256(_campaignPlasma2rebalancingRatio, campaignPlasma));
        return  ratio != 0 ? ratio : 10**18;
    }

    /**
     * @notice          Function to get number of distribution cycles ever
     */
    function getNumberOfCycles()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_numberOfDistributionCycles));
    }


    /**
     * @notice          Function to get how much was initial bounty for selected camapaign in 2KEY tokens
     *
     * @param           campaignPlasma is the plasma address of the campaign
     */
    function getInitialBountyForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma));
    }


    /**
     * @notice          Function to retrieve the initial rate at which 2KEY tokens were bought if
     *                  were bought at all. Otherwise it returns 0.
     * @param           campaignPlasma is plasma address of the campaign
     */
    function getInitial2KEYRateForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2initialRate, campaignPlasma));
    }


    /**
     * @notice          Function to get how much is distributed in cycle
     * @param           cycleId is the ID of that cycle
     */
    function getTotalDistributedInCycle(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_distributionCycleToTotalDistributed, cycleId));
    }


    /**
     * @notice          Function to get moderator rebalanced earnings for this campaign
     * @param           campaignAddress is plasma campaign address
     */
    function getModeratorEarningsRebalancedForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint)
    {
        return (
            getUint(keccak256(_campaignPlasmaToModeratorEarnings, campaignAddress)) //moderator earnings)
        );
    }


    /**
     * @notice          Function to get contractor rebalanced leftover for campaign
     * @param           campaignAddress is plasma campaign address
     */
    function getContractorRebalancedLeftoverForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint)
    {
        return (
            getUint(keccak256(_campaignPlasmaToLeftOverForContractor, campaignAddress)) // contractor leftover
        );
    }


    /**
     * @notice          Function to get moderator earnings and contractor leftover after we rebalanced campaign
     * @param           campaignAddress is the address of campaign
     */
    function getModeratorEarningsAndContractorLeftoverRebalancedForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint,uint)
    {
        return (
            getModeratorEarningsRebalancedForCampaign(campaignAddress),
            getContractorRebalancedLeftoverForCampaign(campaignAddress)
        );
    }

    function getIfLeftoverForCampaignIsWithdrawn(
        address campaignPlasma
    )
    public
    view
    returns (bool)
    {
        bool isWithdrawn = getBool(keccak256(_campaignPlasmaToLeftoverWithdrawnByContractor, campaignPlasma));
        return isWithdrawn;
    }

    function getNonRebalancedReferrerRewards(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma));
    }

    /**
     * @notice          Function to get balance of stable coins on this contract
     * @param           stableCoinsAddresses is the array of stable coins addresses we want to fetch
     *                  balances for
     */
    function getBalanceOfStableCoinsOnContract(
        address [] stableCoinsAddresses
    )
    public
    view
    returns (uint[])
    {
        uint len = stableCoinsAddresses.length;
        uint [] memory balances = new uint[](len);
        uint i;
        for(i = 0; i < len; i++) {
            balances[i] = IERC20(stableCoinsAddresses[i]).balanceOf(address(this));
        }
        return balances;
    }


    /**
     * @notice          Function to check amount of stable coins used to func ppc campaign
     * @param           campaignPlasma is campaign plasma address
     */
    function getAmountOfStableCoinsUsedToFundCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma));
    }

    /**
     * @notice          Function to return bounty per conversion in 2KEY tokens
     * @param           campaignPlasma is plasma campaign of address requested
     */
    function getBountyPerConversion2KEY(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma)
        );
    }

    /**
     * @notice          Function to check if campaign is budgeted directly with 2KEY
     */
    function getIsCampaignBudgetedDirectlyWith2KEY(
        address campaignPlasma
    )
    public
    view
    returns (bool)
    {
        return getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma));
    }

    function getStableCoinAddressUsedToFundCampaign(
        address campaignPlasma
    )
    public
    view
    returns (address)
    {
        return getAddress(keccak256(_campaignPlasma2StableCoinAddress, campaignPlasma));
    }

    /**
     * @notice          Function to return summary related to specific campaign
     * @param           campaignPlasma is plasma campaign of address
     */
    function getCampaignSummary(
        address campaignPlasma
    )
    public
    view
    returns (bytes)
    {
        return (
            abi.encodePacked(
                getInitialBountyForCampaign(campaignPlasma),
                getBountyPerConversion2KEY(campaignPlasma),
                getAmountOfStableCoinsUsedToFundCampaign(campaignPlasma),
                getInitial2KEYRateForCampaign(campaignPlasma),
                getContractorRebalancedLeftoverForCampaign(campaignPlasma),
                getModeratorEarningsRebalancedForCampaign(campaignPlasma),
                getRebalancingRatioForCampaign(campaignPlasma),
                getNonRebalancedReferrerRewards(campaignPlasma),
                getIfLeftoverForCampaignIsWithdrawn(campaignPlasma)
        )
        );
    }

    /**
     * @notice          Function to fetch inital params computed while adding inventory
     * @param           campaignPlasma is the plasma address of the campaign being requested
     */
    function getInitialParamsForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint,uint,uint,bool,address)
    {
        return (
            getInitialBountyForCampaign(campaignPlasma), // initial bounty for campaign
            getBountyPerConversion2KEY(campaignPlasma), // bounty per conversion in 2KEY tokens
            getInitial2KEYRateForCampaign(campaignPlasma), // rate at the moment of inventory adding
            getIsCampaignBudgetedDirectlyWith2KEY(campaignPlasma), // Get if campaign is funded directly with 2KEY
            getCampaignContractor(campaignPlasma) // get contractor of campaign
        );
    }

    function getCampaignContractor(
        address campaignAddress
    )
    public
    view
    returns (address)
    {
        return getAddress(keccak256(_campaignPlasma2contractor, campaignAddress));
    }

    /**
     *
     */
    function getRequiredBudget2KEY(
        string fiatCurrency,
        uint fiatBudgetAmount
    )
    public
    view
    returns (uint)
    {
        // GET 2KEY - USD rate
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // For now ignore fiat currency assuming it's USD always
        return fiatBudgetAmount.mul(10 ** 18).div(rate);
    }

    function getFeePerCycleIdPerReferrer(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_feePerCycleIdPerReferrer, cycleId));
    }

}
