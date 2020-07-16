pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/storage-contracts/ITwoKeyBudgetCampaignsPaymentsHandlerStorage.sol";

contract TwoKeyBudgetCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    /**
     * State variables
     * TO BE EXPANDED
     */

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _contractor2campaignPlasma2RebalancedBudget2Key = "contractor2campaignPlasma2RebalancedBudget2Key";

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

        // Take tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOfTokens
        );

        // Set initial budget added
        setUint(keyHashForInitialBudget, amountOfTokens);
    }


    function pullLeftoverForContractor(
        address campaignPlasmaAddress
    )
    public
    {

    }

    /**
     * ------------------------------------
     *          Maintainer actions
     * ------------------------------------
     */


    function lockContractReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    onlyMaintainer
    {

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


    function incrementNumberOfDistributionCycles()
    internal
    {
        bytes32 key = keccak256(_numberOfDistributionCycles);
        setUint(key,getUint(key) + 1);
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


    function isCampaignEnded(
        address campaignPlasma
    )
    public
    view
    returns (bool)
    {
        // Campaign is ended in terms of accepting new PAID conversion once there's rebalancing ratio > 0
        // No need for any other variables to determine this
    }


}
