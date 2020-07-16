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

    string constant _contractor2campaignPlasma2initialBudget2Key = "contractor2campaignPlasma2initialBudget2Key";
    string constant _contractor2campaignPlasma2RebalancedBudget2Key = "contractor2campaignPlasma2RebalancedBudget2Key";

    string constant _campaignPlasma2initalRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2rebalancedRate = "campaignPlasma2rebalancedRate";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";

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


    function addDirectly2KEYAsInventory(
        address campaignPlasma,
        uint amountOfTokens
    )
    public
    {
        bytes32 keyHashForInitialBudget = keccak256(_contractor2campaignPlasma2initialBudget2Key, msg.sender, campaignPlasma);
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


    function setAndDistributeModeratorRewardsForCampaign(
        address campaignPlasma
    )
    onlyMaintainer
    {

    }


    function lockContractReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForRewards
    )
    onlyMaintainer
    {

    }


    function pushAndDistributeRewardsBetweenInfluencers(
        address campaignPlasma,
        address [] influencers,
        uint [] balances
    )
    public
    onlyMaintainer
    {

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


    /**
     * ------------------------------------------------
     *              Public getters
     * ------------------------------------------------
     */

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
