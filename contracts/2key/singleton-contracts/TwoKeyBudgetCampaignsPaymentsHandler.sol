pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/storage-contracts/ITwoKeyBudgetCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/IUpgradableExchange.sol";

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

    string constant _campaignPlasma2initialRate = "campaignPlasma2initalRate";

    string constant _numberOfDistributionCycles = "numberOfDistributionCycles";
    string constant _distributionCycleToTotalDistributed = "_distributionCycleToTotalDistributed";

    string constant _campaignPlasmaToModeratorEarnings = "campaignPlasmaToModeratorEarnings";
    string constant _campaignPlasmaToLeftOverForContractor = "campaignPlasmaToLeftOverForContractor";
    string constant _campaignPlasmaToLeftoverWithdrawnByContractor = "campaignPlasmaToLeftoverWithdrawnByContractor";

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
     *                  directly with 2KEY tokens or using DAI tokens. In order to make this
     *                  transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOfTokens is the amount of tokens user adds as inventory in token currency.
     */
    function addInventory(
        address campaignPlasma,
        uint amountOfTokens,
        string tokenSymbol
    )
    public
    payable
    {
        bytes32 keyHashForInitialBudget = keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma);

        // Require that initial budget is not being added, since it can be done only once.
        require(getUint(keyHashForInitialBudget) == 0);

        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        if(equals(tokenSymbol, "2KEY")) {
            // Take tokens from the contractor
            IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
                msg.sender,
                address(this),
                amountOfTokens
            );
            // Set initial budget added
            setUint(keyHashForInitialBudget, amountOfTokens);
        } else if (equals(tokenSymbol, "DAI")) {
            // Take tokens from the contractor
            IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI")).transferFrom(
                msg.sender,
                address(this),
                amountOfTokens
            );
            //TODO: Leftover to compute how much is this worth in 2KEY tokens and store that rate (2KEY/USD)
        } else {
            revert('Token symbol is not supported.');
        }
    }



    function pullLeftoverForContractor(
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

        // Check that he has some leftover
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

        // Neutral for rebalancing = 1ETH
        uint rebalancingRatio = 10**18;

        // If budget added directly as 2KEY it will be 0
        uint initial2KEYRate = getInitial2KEYRateForCampaign(campaignPlasma);

        if(initial2KEYRate > 0) {
            (amountToRebalance, rebalancingRatio)
                = rebalanceRates(
                    initial2KEYRate,
                    amountToRebalance
            );
        }

        uint rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);
        uint leftoverForContractor = amountToRebalance.sub(rebalancedModeratorRewards);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Leftover for contractor
        setUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasma),
            leftoverForContractor
        );

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
        uint rebalancedTotalPayout
    )
    public
    onlyMaintainer
    {
        // Increment distribution cycle id
        incrementNumberOfDistributionCycles();
        // The new one (latest) is the id of this cycle
        uint cycleId = getNumberOfCycles();
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
            // TODO: Finish this funnel and add event

        } else {
            // Leads to we need to get more tokens from Upgradable Exchange
            difference = rebalancedTotalPayout.sub(nonRebalancedTotalPayout);
            // TODO: Finish this funnel and add event
        }

        // Iterate through all influencers, distribute them rewards, and account amount received per cycle id
        for(i = 0; i < influencers.length; i++) {
            // Take the influencer balance
            uint balance = balances[i];
            // Transfer required tokens to influencer
            IERC20(twoKeyEconomy).transfer(influencers[i], balance);
            // Sum up to totalDistributed
            totalDistributed = totalDistributed.add(balance);
        }

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
        ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModerator(rebalancedModeratorRewards);
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

        uint rebalancingRatio = initial2KEYRate.mul(10**18).div(usd2KEYRateWeiNow);

        // Calculate new rebalanced amount of tokens
        uint rebalancedAmount = amountOfTokensToRebalance.mul(rebalancingRatio);

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
     * ------------------------------------------------
     *              Public getters
     * ------------------------------------------------
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

    function getTotalDistributedInCycle(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_distributionCycleToTotalDistributed, cycleId));
    }

}
