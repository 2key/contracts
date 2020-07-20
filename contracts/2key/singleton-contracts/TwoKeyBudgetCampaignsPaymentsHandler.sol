pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/storage-contracts/ITwoKeyBudgetCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/ITwoKeyAdmin.sol";

import "../libraries/SafeMath.sol";

contract TwoKeyBudgetCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    /**
     * State variables
     * TO BE EXPANDED
     */

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _contractor2campaignPlasma2RebalancedBudget2Key = "contractor2campaignPlasma2RebalancedBudget2Key";
    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2contractor = "campaignPlasma2contractor";

    string constant _campaignPlasma2initalRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2rebalancedRate = "campaignPlasma2rebalancedRate";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";

    string constant _numberOfDistributionCycles = "numberOfDistributionCycles";
    string constant _globalDistributionCycleId2referrer2amountDistributed = "globalDistributionCycleId2referrer2amountDistributed";
    string constant _totalAmountDistributedToReferrerEver = "totalAmountDistributedToReferrerEver";

    string constant _campaignPlasmaToReservedAmountForRewards = "campaignPlasmaToReservedAmountForRewards";
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


    function buyReferralBudgetWithETH(
        address campaignPlasmaAddress
    )
    public
    payable
    {
        //TODO: Think about DAI payments instead of ETH, and buy inventory with DAI
    }


    /**
     * @notice          Function which will be used in order to add inventory for campaign
     *                  directly with 2KEY tokens. In order to make this transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOfTokens is the amount of tokens user adds as inventory.
     */
    function addDirectly2KEYAsInventory(
        address campaignPlasma,
        uint amountOfTokens
    )
    public
    {
        bytes32 keyHashForInitialBudget = keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma);

        // Require that initial budget is not being added, since it can be done only once.
        require(getUint(keyHashForInitialBudget) == 0);
        // Set initial budget added
        setUint(keyHashForInitialBudget, amountOfTokens);

        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        // Take tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOfTokens
        );

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


    //TODO: Discuss with @eitan there's no need to store total amount for referrer rewards.
    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    onlyMaintainer
    {
        // Generate key for storage variable isCampaignEnded
        bytes32 keyIsCampaignEnded = keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma);

        // Require that campaign is not ended yet
        require(getBool(keyIsCampaignEnded) == false);

        // End campaign
        setBool(keyIsCampaignEnded, true);

        // Get how many tokens were inserted at the beginning
        uint amountOfTokensOnCampaign = getInitialBountyForCampaign(campaignPlasma);

        // Require that there was enough tokens to support this operation
        require(
            totalAmountForModeratorRewards + totalAmountForReferrerRewards <= amountOfTokensOnCampaign
        );

        uint initial2KEYRate = getUint(keccak256(_campaignPlasma2initalRate,campaignPlasma));

        uint rebalancingRatio = 10**18;

        if(initial2KEYRate > 0) {
            (amountOfTokensOnCampaign, rebalancingRatio)
                = rebalanceRates(campaignPlasma, amountOfTokensOnCampaign);
        } else {
            // Set that rebalancing ratio is 0 in other case
            setUint(keccak256(_campaignPlasma2rebalancingRatio,campaignPlasma), rebalancingRatio);
        }

        uint rebalancedReferrerRewards = totalAmountForReferrerRewards.mul(rebalancingRatio).div(10**18);
        uint rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Reserve amount for influencers
        setUint(
            keccak256(_campaignPlasmaToReservedAmountForRewards, campaignPlasma),
            rebalancedReferrerRewards
        );

        // Leftover for contractor
        setUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasma),
            amountOfTokensOnCampaign.sub(rebalancedReferrerRewards.add(rebalancedModeratorRewards))
        );

    }


    /**
     * @notice          Function to distribute rewards between influencers
     *
     * @param           influencers is the array of influencers
     * @param           balances is the array of corresponding balances for the influencers above
     *
     */
    function pushAndDistributeRewardsBetweenInfluencers(
        address [] influencers,
        uint [] balances
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

        uint i;
        // Iterate through all influencers, distribute them rewards, and account amount received per cycle id
        for(i = 0; i < influencers.length; i++) {
            // Take the influencer balance
            uint balance = balances[i];
            // Transfer required tokens to influencer
            IERC20(twoKeyEconomy).transfer(influencers[i], balance);
            // Generate the storage key for influencer
            bytes32 key = keccak256(
                _globalDistributionCycleId2referrer2amountDistributed,
                cycleId,
                influencers[i]
            );
            // Set how much was distributed to this referrer in this cycle
            setUint(key, balance);
        }
    }

    /**
     * ------------------------------------------------
     *        Internal functions performing logic operations
     * ------------------------------------------------
     */

    function rebalanceRates(
        address campaignPlasma,
        uint amountOfTokens
    )
    internal
    returns (uint,uint)
    {
        // TODO: Implement logic
        return (amountOfTokens, 10**18);
    }


    function setAndDistributeModeratorEarnings(
        address campaignPlasma,
        uint rebalancedModeratorRewards
    )
    internal
    {
        // Reserve amount for moderator
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


    function getDistributedAmountToReferrerByCycleId(
        address referrer,
        uint cycleId
    )
    public
    view
    returns (uint)
    {

    }


    function getTotalAmountDistributedToReferrer(
        address referrer
    )
    public
    view
    returns (uint)
    {

    }

    function getInitialBountyForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma));
    }

    function getBountyStatsPerCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint,uint,uint,uint)
    {
        // return (totalInitial, bountyAfterRebalancing, reservedForRewards, contractorLeftover)
    }


    function getRebalancingResults(
        address campaignPlasma
    )
    public
    view
    returns (uint,uint,uint)
    {
        // return (price before, price after, ratio)
    }

}
