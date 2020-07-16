pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

contract TwoKeyBudgetCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    /**
     * State variables
     * TO BE EXPANDED
     */

    string constant _contractor2campaignPlasma2budget = "contractor2campaign2budget";
    string constant _contractor2campaignPlasma2RebalancedBudget = "contractor2campaignPlasma2RebalancedBudget";

    string constant _campaignPlasma2initalRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2rebalancedRate = "campaignPlasma2rebalancedRate";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";

    string constant _globalDistributionCycleId2referrer2amountDistributed = "globalDistributionCycleId2referrer2amountDistributed";
    string constant _totalAmountDistributedToReferrerEver = "totalAmountDistributedToReferrerEver";

    string constant _campaignPlasmaToReservedAmountForRewards = "campaignPlasmaToReservedAmountForRewards";
    string constant _campaignPlasmaToModeratorEarnings = "campaignPlasmaToModeratorEarnings";
    string constant _campaignPlasmaToLeftOverForContractor = "campaignPlasmaToLeftOverForContractor";
    string constant _campaignPlasmaToLeftoverWithdrawnByContractor = "campaignPlasmaToLeftoverWithdrawnByContractor";


    function setInitialParams()
    public
    {

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
        address contractorAddress,
        uint amountOfTokens
    )
    public
    {

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
     * ------------------------------------
     *        Getters and stats
     * ------------------------------------
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
        // return (totalBounty, bountyAfterRebalancing, reservedForRewards, contractorLeftover)
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
