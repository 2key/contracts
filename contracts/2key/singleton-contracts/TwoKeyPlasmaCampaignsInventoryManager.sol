pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryManagerStorage.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";
import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/ITwoKeyPlasmaCampaign.sol";

import "../libraries/SafeMath.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventoryManager contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventoryManager is Upgradeable {

    using SafeMath for uint;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryManagerStorage PROXY_STORAGE_CONTRACT;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";
    string constant _twoKeyCPCCampaignPlasma = "TwoKeyCPCCampaignPlasma";

    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2LeftOverForContractor = "campaignPlasma2LeftOverForContractor";
    string constant _campaignPlasma2ReferrerRewardsTotal = "campaignPlasma2ReferrerRewardsTotal";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";
    string constant _campaignPlasma2Budget2Key = "campaignPlasma2Budget2Key";
    string constant _campaignPlasma2BudgetUSD = "campaignPlasma2BudgetUSD";
    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2bountyPerConversionUSD = "campaignPlasma2bountyPerConversionUSD";
    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";   // msg.sender
    string constant _campaignPlasma2LeftoverWithdrawnByContractor = "campaignPlasma2LeftoverWithdrawnByContractor";
    string constant _distributionCycle2TotalDistributed = "distributionCycle2TotalDistributed";

    string constant _numberOfCycles = "numberOfCycles";

    // // Mapping cycle id to total non rebalanced amount payment
    // string constant _distributionCycle2TotalNonRebalancedPayment = "distributionCycle2TotalNonRebalancedPayment";
    // // Mapping cycle id to total rebalanced amount payment
    // string constant _distributionCycleToTotalRebalancedPayment = "distributionCycleToTotalRebalancedPayment";
    // Mapping referrer to all campaigns he participated at and are having pending distribution
    string constant _referrer2pendingCampaignAddresses = "referrer2pendingCampaignAddresses";
    // // Mapping referrer to how much 2KEY he has in pending
    // string constant _referrer2Payout2KEY = "referrer2Payout2KEY";
    // // Mapping referrer to how much USD he has in pending
    // string constant _referrer2PayoutUSD = "referrer2PayoutUSD";
    // Mapping referrer to all campaigns that are in progress of distribution
    string constant _referrer2inProgressCampaignAddress = "referrer2inProgressCampaignAddress"; //TODO: no need for this, can delete
    // // Mapping referrer to how much rebalanced amount in progress he has
    // string constant _referrer2rebalancedTotalPayout = "referrer2rebalancedTotalPayout";
    // Mapping distribution cycle to referrers being paid in that cycle
    // string constant _distributionCycleIdToReferrersPaid = "distributionCycleIdToReferrersPaid";
    // // Mapping referrer to all campaigns he already received a payment
    string constant _referrer2finishedAndPaidCampaigns = "referrer2finishedAndPaidCampaigns";


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
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaCampaignsInventoryManagerStorage(_proxyStorage);

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
     * @notice          Function can be called several times
     */
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversion2KEY,
        address campaignAddressPlasma
    )
    public
    {
        // Allow a user add the budget several times but in same token
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0) || 
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == msg.sender
        );

        if (PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0)) {    // Initialize the campaign
            uint rate = 10**18;
            // Set contractor user
            PROXY_STORAGE_CONTRACT.setAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma), msg.sender);
            // Set the amount of 2KEY
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma), amount);
            // Set 2Key bounty per conversion value
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignAddressPlasma), bountyPerConversion2KEY);
            // Set true value for 2Key directly budgeting
            PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma), true);

            // Perform direct 2Key transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transfer2KEYFrom(msg.sender, campaignAddressPlasma, amount);

            // Set initial parameters and validates campaign
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, true);

        } else {    // Add the budget
            // Update total 2Key
            uint currentAmount = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma), currentAmount.add(amount));

            // Perform direct 2Key transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transfer2KEYFrom(msg.sender, campaignAddressPlasma, amount);

            // Change CPC campaign parameters
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .addCampaignBounty(amount, true);
        }

        // Emit an event that the inventory is added in L2_2KEY
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitAddInventory2KEY(
                amount,
                bountyPerConversion2KEY,
                campaignAddressPlasma
            );
    }

    /**
     * @notice          Function that allocates specified amount of USD from users balance to this contract's balance
     * @notice          Function can be called several times
     */
    function addInventoryUSD(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Allow a user add the budget several times but in same token
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0) || 
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == msg.sender
        );

        if (PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0)) {    // Initialize the campaign
            uint rate = 10**18;
            // Set contractor user
            PROXY_STORAGE_CONTRACT.setAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma), msg.sender);
            // Set amount of Stable coins
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma), amount);
            // Set current bountyPerConversionUSD
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2bountyPerConversionUSD, campaignAddressPlasma), bountyPerConversionUSD);
            // Set false value for non-2Key budgeting
            PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma), false);

            // Perform a transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transferUSDFrom(msg.sender, campaignAddressPlasma, amount);

            // Set initial parameters and validates campaign
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversionUSD, false);

        } else {    // Add the budget
            // Update total stable coins
            uint currentAmount = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma), currentAmount.add(amount));

            // Perform a transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transferUSDFrom(msg.sender, campaignAddressPlasma, amount);
            
            // Change CPC campaign parameters
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .addCampaignBounty(amount, false);
        }

        // Emit an event that the inventory is added in L2_USD
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitAddInventoryUSD(
                amount,
                bountyPerConversionUSD,
                campaignAddressPlasma
            );
    }


    // /**
    //  * @notice          Function where maintainer will submit N calls and store campaign
    //  *                  inside array of campaigns for influencers that it's not distributed but ended
    //  *
    //  *                  END CAMPAIGN OPERATION ON PLASMA CHAIN
    //  * @param           campaignPlasma is the plasma address of campaign
    //  * @param           start is the start index
    //  * @param           end is the ending index
    //  */
    // function markCampaignAsDoneAndAssignToActiveInfluencers(
    //     address campaignPlasma,
    //     uint start,
    //     uint end
    // )
    // public
    // onlyMaintainer
    // {
    //     address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");

    //     address[] memory influencers = ITwoKeyPlasmaCampaign(campaignPlasma).getActiveInfluencers(start,end);

    //     uint i;
    //     uint len = influencers.length;

    //     for(i=0; i<len; i++) {
    //         address referrer = influencers[i];

    //         ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitAddedPendingRewards(
    //             campaignPlasma,
    //             referrer,
    //             ITwoKeyPlasmaCampaign(campaignPlasma).getReferrerPlasmaBalance(referrer)
    //         );

    //         bytes32 key = keccak256(
    //             _referrer2pendingCampaignAddresses,
    //             referrer
    //         );

    //         pushAddressToArray(key, campaignPlasma);
    //     }
    }

    // /**
    //  * @notice          At the point when we want to do the payment
    //  */
    // //TODO:1. specific user wants to withdraw their earnings
    // //TODO:2. maintainer calls function, which goes over their curent earnings, cycles over all their pending campaigns (campaigns with rewards)
    // //TODO:3. if rewards in 2KEY, remain as 2KEY, if in USDT, keep in USDT
    // //TODO:4. eventually, we get the total 2KEY and total USDT payable to the referrer, and from each such campaign, we need to call transfer of the required amounts from each campaign to the balance of the referrer
    // //TODO:5. example: referrer has 10 2KEY rewards in campaign1 and 20 USDT rewards in campaign2 --> call to transfer 10 2KEY and 20USDT from the campaigns to the balance of the referer in L2
    // //TODO:6. in the end of this process - campaigns have less balance on layer2 account manager, and referrer has more
    // //TODO:7. later, in another call, the user can withdraw value back to Layer1, and it withdrawable as 2KEY - so then, if he withdraw USDT value, has to withdraw as 2KEY using rate from maintainer
    // function withdrawTotalReferrerEarnings(
    //     address referrer
    // )
    // public
    // onlyMaintainer
    // {
    //     address[] memory referrerCampaigns = getCampaignsReferrerHasPendingBalances(referrer);

    //     // Iterate through campaigns
    //     for(uint j = 0; j < referrerCampaigns.length; j++) {
    //         // Load campaign address
    //         address campaignAddress = referrerCampaigns[j];

    //         ITwoKeyPlasmaCampaign(campaignAddress).transferReferrerCampaignEarnings(referrer);
    //     }
    // }

     /**
      * @notice          At the point when we want to do the payment
      */
    function withdrawReferrerPendingRewards(
        address referrer,
        uint feePerReferrerIn2KEY //TODO remove fee
    )
    public
    onlyMaintainer
    {
        // Get all the campaigns of specific referrer
        address[] memory referrerCampaigns = getCampaignsReferrerHasPendingBalances(referrer);

        uint referrerTotalPayoutUSD;
        uint referrerTotalPayout2KEY;

        uint referrerPayoutOfCampaign;
        // Iterate through campaigns
        for(uint j = 0; j < referrerCampaigns.length; j++) {
            // Load campaign address
            address campaignAddress = referrerCampaigns[j];
            // Transfer plasma balance to referrer
            ITwoKeyPlasmaCampaign(campaignAddress).transferReferrerCampaignEarnings(referrer, feePerReferrerIn2KEY); //TODO: remove fee
            // Transfer fee to admin
            transferFeesToAdmin(campaignAddressPlasma, feePerReferrerIn2Key, 1);//TODO this is l1 logic, no need for it (no fee is taken now)
        }

        //TODO remove this part
        // Move from inProgress to finished campagins
        appendToArray(
            keccak256(_referrer2finishedAndPaidCampaigns, referrer),
            keccak256(_referrer2pendingCampaignAddresses, referrer)
        );

        // Delete array of inProgress campaigns
        deleteAddressArray(
            keccak256(_referrer2pendingCampaignAddresses, referrer)
        );

        //TODO still missing to add the part where the balance on each campaign is updated back to zero
    }


    //TODO can remove this
    function finishDistributionCycle(
        address referrer,
        uint feePerReferrerIn2KEY
    )
    public
    onlyMaintainer
    {
        // address[] memory referrers = getReferrersForCycleId(cycleId);

        // uint i;

        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        // Iterate through all referrers
        // for(i=0; i<referrers.length; i++) {
        //     // Take referrer address
        //     address referrer = referrers[i];

            address [] memory referrerInProgressCampaigns = getCampaignsInProgressOfDistribution(referrer);
            // Create array of referrer earnings per campaign
            uint [] memory referrerEarningsPerCampaign = new uint [](referrerInProgressCampaigns.length);
            // Get referrer earnings for this campaign and mark referrel got paid his campaign
            referrerEarningsPerCampaign = getReferrerEarningsAndMarkReferrerPaid(referrer, referrerInProgressCampaigns);

            ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitPaidPendingRewards(
                referrer,
                getReferrerEarningsNonRebalanced(referrer), //amount non rebalanced referrer earned
                getReferrerEarningsRebalanced(referrer), // amount paid to referrer
                referrerInProgressCampaigns,
                referrerEarningsPerCampaign,
                feePerReferrerIn2KEY
            );

            // Move from inProgress to finished campagins
            appendToArray(
                keccak256(_referrer2finishedAndPaidCampaigns, referrer),
                keccak256(_referrer2inProgressCampaignAddress, referrer)
            );

            // Delete array of inProgress campaigns
            deleteAddressArray(
                keccak256(_referrer2inProgressCampaignAddress, referrer)
            );
        // }
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
    function endCampaignReserveTokensAndRebalanceRates(  //TODO: rename to endCampaignAndTransferModeratorEArnings
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    public
    onlyMaintainer
    {
        // Check if campaign has not ended yet
        require(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma)) == false);
        // Setting bool that campaign is over
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma), true);

        // Get how many tokens were inserted at the beginning
        uint initialBountyForCampaign;
        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma)) == true) {
            // if campaign was directly budgeted with 2KEY
            initialBountyForCampaign = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignPlasma));
        } else {
            // if campaign was budgeted with stable coin
            initialBountyForCampaign = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignPlasma));
        }
        // Rebalancing everything except referrer rewards
        uint amountToRebalance = initialBountyForCampaign.sub(totalAmountForReferrerRewards);
        // Amount after rebalancing is initially amount to rebalance
        uint amountAfterRebalancing = amountToRebalance;
        // Initially rebalanced moderator rewards are total moderator rewards
        uint rebalancedModeratorRewards = totalAmountForModeratorRewards;
        // Initial ratio is 10**18
        uint rebalancingRatio = 10**18;

        // We do rebalancing if campaign was not directly budgeted with 2KEY
        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma)) == false) {
            // Rebalance rates
            (amountAfterRebalancing, rebalancingRatio)
                = rebalanceRates(
                    amountToRebalance
                );
            // Get rebalanced value of totalAmountForModeratorRewards
            rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);
        }

        uint leftoverForContractor = amountAfterRebalancing.sub(rebalancedModeratorRewards);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Set total amount to use for referrers
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma), totalAmountForReferrerRewards);
        // Leftover for contractor
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignPlasma), leftoverForContractor);
        // Set rebalancing ratio for campaign
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2rebalancingRatio, campaignPlasma), rebalancingRatio);

        // Emit an event to checksum all the balances per campaign
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitEndedBudgetCampaign(
                campaignPlasma,
                leftoverForContractor,
                rebalancedModeratorRewards
            );
    }

    /**
     * @notice      Function to rebalance the rates
     *
     * @param       amountOfTokensToRebalance is number of tokens left
     */
    function rebalanceRates(
        uint amountOfTokensToRebalance
    )
    internal
    returns (uint, uint)
    {
        address twoKeyPlasmaAccountManager = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager);

        // Take the current usd to 2KEY rate against we're rebalancing contractor leftover and moderator rewards
        uint usd2KEYRateWeiNow = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaExchangeRate"))
            .getPairValue("2KEY-USD");

        uint rebalancingRatio = usd2KEYRateWeiNow;

        // Calculate rebalanced amount of tokens
        uint rebalancedAmount = amountOfTokensToRebalance.mul(rebalancingRatio).div(10**18);
        
        // Return rebalanced amount as well as ratio against which rebalancing was done.
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
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2ModeratorEarnings, campaignPlasma), rebalancedModeratorRewards);

        // Address to transfer moderator (2key admin contract) earnings to
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Transfer 2KEY tokens to moderator
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).transfer2KEYFrom(
            campaignPlasma,
            twoKeyAdmin,
            rebalancedModeratorRewards
        );

        // Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
        ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModeratorPPC(rebalancedModeratorRewards, campaignPlasma);
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
        // Require that msg.sender is contractor who created the campaign
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignPlasmaAddress)) == msg.sender
        );
        // Get leftoverForContractor
        uint leftoverForContractor = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignPlasmaAddress));
        // Require that there is an existing amount of leftoverForContractor
        require(leftoverForContractor > 0);
        // Require that contractor has not already withdrawn the leftover
        require(
            PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignPlasmaAddress)) == false
        );
        // Set value that contractor did perform the withdraw
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignPlasmaAddress), true);
        // Perform transfer of leftover to contractor
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
            .transfer2KEYFrom(
                campaignPlasmaAddress,
                msg.sender,
                leftoverForContractor
            );
    }


    // /**
    //  * @notice      Function to distribute rewards between influencers,
    //  *              increment global cycle id and update value of all time
    //  *              distributed rewards from this contract
    //  *
    //  * @param       influencers is the array of influencers
    //  * @param       balances is a corresponding array of balances for influencers
    //  */
    // function pushAndDistributeRewardsBetweenInfluencers(
    //     address[] influencers,
    //     uint[] balances,
    //     address campaignAddressPlasma,
    //     uint feePerReferrerIn2Key,
    // )
    // public
    // onlyMaintainer
    // {
    //     // Address of twoKeyPlasmaAccountManager contract
    //     address twoKeyPlasmaAccountManager = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager);
    //     // Total distributed in cycle
    //     uint totalDistributed;

    //     // Get number of referrers
    //     uint numberOfReferrers = influencers.length;

    //     // Iterate through all influencers, distribute rewards and sum up the amount received in current cycle
    //     for(uint i = 0; i < numberOfReferrers; i++) {
    //         // Require that referrer's earnings are bigger than fees
    //         require(balances[i] > feePerReferrerIn2Key);
    //         // Sub fee per referrer from balance to pay and transfer tokens to influencer
    //         uint balance = balances[i].sub(feePerReferrerIn2Key);
    //         ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
    //             .transfer2KEYFrom(campaignAddressPlasma, influencers[i], balance);
    //         // Sum up to totalDistributed to referrers
    //         totalDistributed = totalDistributed.add(balance);
    //     }

    //     transferFeesToAdmin(campaignAddressPlasma, feePerReferrerIn2Key, numberOfReferrers);

    //     // Set how much is total distributed per distribution cycle
    //     PROXY_STORAGE_CONTRACT.setUint(
    //         keccak256(_distributionCycle2TotalDistributed),
    //         totalDistributed
    //     );
    // }

    /**
     * @notice          Function to transfer fees taken from referrer rewards to admin contract
     * @param           feePerReferrer is fee taken per referrer equaling 0.5$ in 2KEY at the moment
     * @param           numberOfReferrers is number of referrers being rewarded in this cycle
     */
    function transferFeesToAdmin(
        address campaignAddressPlasma,
        uint feePerReferrer,
        uint numberOfReferrers
    )
    internal
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Transfer 2KEY tokens to moderator
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).transfer2KEYFrom(
            campaignAddressPlasma,
            twoKeyAdmin,
            feePerReferrer.mul(numberOfReferrers)
        );

        // Update in admin tokens receiving from fees
        ITwoKeyAdmin(twoKeyAdmin).updateTokensReceivedFromDistributionFees(feePerReferrer.mul(numberOfReferrers));
    }

    // function updateRebalanceNonRebalanceAmount(
    //     address[] memory referrerCampaigns,
    //     address referrer,
    //     uint256 currentRate2KEY
    // )
    // internal
    // returns (uint, uint, uint)
    // {
    //     uint referrerTotalPayoutAmount;
    //     uint referrerTotalNonRebalancedAmountForCycle;
    //     uint amountToBeDistributedInCycleNoRebalanced;

    //     // Iterate through campaigns
    //     for(uint j = 0; j < referrerCampaigns.length; j++) {
    //         // Load campaign address
    //         address campaignAddress = referrerCampaigns[j];

    //         uint rebalancedAmount;
    //         uint nonRebalancedAmount;

    //         // Update on plasma campaign contract rebalancing ratio at this moment
    //         (rebalancedAmount, nonRebalancedAmount) = ITwoKeyPlasmaCampaign(campaignAddress).computeAndSetRebalancingRatioForReferrer(
    //             referrer,
    //             currentRate2KEY
    //         );

    //         referrerTotalPayoutAmount = referrerTotalPayoutAmount.add(rebalancedAmount);

    //         // Store referrer total non-rebalanced amount
    //         referrerTotalNonRebalancedAmountForCycle = referrerTotalNonRebalancedAmountForCycle.add(nonRebalancedAmount);

    //         // Update total payout to be paid in case there was no rebalancing
    //         amountToBeDistributedInCycleNoRebalanced = amountToBeDistributedInCycleNoRebalanced.add(nonRebalancedAmount);
    //     }

    //     return (referrerTotalPayoutAmount, referrerTotalNonRebalancedAmountForCycle, amountToBeDistributedInCycleNoRebalanced);
    // }

    // function getReferrerEarningsAndMarkReferrerPaid(
    //     address referrer,
    //     address[] memory referrerInProgressCampaigns
    // )
    // internal
    // returns (uint[])
    // {
    //     uint[] memory referrerEarningsPerCampaign = new uint [](referrerInProgressCampaigns.length);
    //     for(uint j = 0; j < referrerInProgressCampaigns.length; j++) {
    //         // Load campaign address
    //         address campaignAddress = referrerInProgressCampaigns[j];

    //         // Get referrer earnings for this campaign
    //         referrerEarningsPerCampaign[j] = ITwoKeyPlasmaCampaign(campaignAddress).getRefererrerRewardsBalance(referrer);

    //         // Mark that referrer got paid his campaign
    //         ITwoKeyPlasmaCampaign(campaignAddress).markReferrerReceivedPaymentForThisCampaign(referrer);

    //     }

    //     return referrerEarningsPerCampaign;
    // }


    function appendToArray(
        bytes32 keyBaseArray,
        bytes32 keyArrayToAppend
    )
    internal
    {
        address [] memory baseArray = PROXY_STORAGE_CONTRACT.getAddressArray(keyBaseArray);
        address [] memory arrayToAppend = PROXY_STORAGE_CONTRACT.getAddressArray(keyArrayToAppend);

        uint len = baseArray.length + arrayToAppend.length;

        address [] memory newBaseArray = new address[](len);

        uint i;
        uint j;

        // Copy base array
        for(i=0; i< baseArray.length; i++) {
            newBaseArray[i] = baseArray[i];
        }

        // Copy array to append
        for(i=baseArray.length; i<len; i++) {
            newBaseArray[i] = arrayToAppend[j];
            j++;
        }

        PROXY_STORAGE_CONTRACT.setAddressArray(keyBaseArray, newBaseArray);
    }

    function pushAddressToArray(
        bytes32 key,
        address value
    )
    internal
    {
        address[] memory currentArray = PROXY_STORAGE_CONTRACT.getAddressArray(key);

        uint newLength = currentArray.length + 1;

        address [] memory newArray = new address[](newLength);

        uint i;

        for(i=0; i<newLength - 1; i++) {
            newArray[i] = currentArray[i];
        }

        // Append the last value there.
        newArray[i] = value;

        // Store this array
        PROXY_STORAGE_CONTRACT.setAddressArray(key, newArray);
    }


    /**
     * @notice          Function to get campaign where referrer is having pending
     *                  balance. If empty array, means all rewards are already being
     *                  distributed.
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    public
    view
    returns (address[]) {
        bytes32 key = keccak256(
            _referrer2pendingCampaignAddresses,
            referrer
        );

        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

    /**
     * @notice          Function to fetch total pending payout on all campaigns that
     *                  are not inProgress of payment yet for influencer
     * @param           referrer is the address of referrer
     */
    function getTotalReferrerPendingAmount(
        address referrer
    )
    public
    view
    returns (uint)
    {
        // Get all pending campaigns for this referrer
        address[] memory campaigns = getCampaignsReferrerHasPendingBalances(referrer);

        uint i;
        uint referrerTotalPendingPayout;

        // Iterate through all campaigns
        for(i = 0; i < campaigns.length; i++) {
            // Add to total pending payout referrer plasma balance
            referrerTotalPendingPayout = referrerTotalPendingPayout.add(ITwoKeyPlasmaCampaign(campaigns[i]).getReferrerPlasmaBalance(referrer));
        }

        // Return referrer total pending
        return referrerTotalPendingPayout;
    }

//    /**
//     * @notice          Function to get total payout for specific cycle non rebalanced
//     * @param           cycleId is the id of distribution cycle
//     */
//    function getTotalNonRebalancedPayoutForCycle(
//        uint cycleId
//    )
//    public
//    view
//    returns (uint)
//    {
//        return PROXY_STORAGE_CONTRACT.getUint(
//            keccak256(_distributionCycle2TotalNonRebalancedPayment, cycleId)
//        );
//    }

//    /**
//     * @notice          Function to get total rebalanced payout for specific cycle rebalanced
//     * @param           cycleId is the id of distribution cycle
//     */
//    function getTotalRebalancedPayoutForCycle(
//        uint cycleId
//    )
//    public
//    view
//    returns (uint)
//    {
//        return PROXY_STORAGE_CONTRACT.getUint(
//            keccak256(_distributionCycleToTotalRebalancedPayment, cycleId)
//        );
//    }

    // /**
    //  * @notice          Function to get amount of non rebalanced earnings
    //  *                  per specific cycle per referrer
    //  * @param           referrer is the referrer address
    //  * @param           cycleId is the ID of the cycle.
    //  */
    // function getReferrerEarningsNonRebalanced(
    //     address referrer
    // )
    // public
    // view
    // returns (uint)
    // {
    //     return PROXY_STORAGE_CONTRACT.getUint(
    //         keccak256(
    //             _referrer2nonRebalancedAmount
    //         )
    //     );
    // }

    // /**
    //  * @notice          Function to get how much rebalanced earnings referrer got
    //  *                  for specific distribution cycle id
    //  * @param           referrer is the referrer plasma address
    //  * @param           cycleId is distribution cycle id
    //  */
    // function getReferrerEarningsRebalanced(
    //     address referrer
    // )
    // public
    // view
    // returns (uint)
    // {
    //     return PROXY_STORAGE_CONTRACT.getUint(
    //         keccak256(
    //             _referrer2rebalancedAmount,
    //             referrer
    //         )
    //     );
    // }

    /**
     * @notice          Function to get campaign where referrer balance is rebalanced
     *                  but still not submitted to mainchain
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsInProgressOfDistribution(
        address referrer
    )
    public
    view
    returns (address[])
    {
        bytes32 key = keccak256(
            _referrer2inProgressCampaignAddress,
            referrer
        );

        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

//    /**
//     * @notice          Function to get referrers for cycle id
//     * @param           cycleId is the cycle id we want referrers paid in
//     */
//    function getReferrersForCycleId(
//        uint cycleId
//    )
//    public
//    view
//    returns (address[])
//    {
//        return PROXY_STORAGE_CONTRACT.getAddressArray(
//            keccak256(_distributionCycleIdToReferrersPaid, cycleId)
//        );
//    }

//    /**
//     * @notice          Function to get pending balances for influencers to be distributed
//     * @param           referrers is the array of referrers passed previously to function
//     *                  rebalanceInfluencerRatesAndPrepareForRewardsDistribution
//     */
//    function getPendingReferrersPaymentInformationForCycle(
//        address [] referrers,
//        uint cycleId
//    )
//    public
//    view
//    returns (uint[],uint,uint)
//    {
//        uint numberOfReferrers = referrers.length;
//        uint [] memory balances = new uint[](numberOfReferrers);
//        uint totalRebalanced;
//        uint i;
//        for(i = 0; i < numberOfReferrers; i++) {
//            balances[i] = getReferrerToTotalRebalancedAmountForCycleId(referrers[i], cycleId);
//            totalRebalanced = totalRebalanced.add(balances[i]);
//        }
//
//        return (
//            balances,
//            totalRebalanced,
//            getTotalNonRebalancedPayoutForCycle(cycleId)
//        );
//    }

    /**
     * @notice          Function where we can fetch finished and paid campaigns for referrer
     * @param           referrer is the address of referrer
     */
    function getCampaignsFinishedAndPaidForReferrer(
        address referrer
    )
    public
    view
    returns (address[])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(
            keccak256(_referrer2finishedAndPaidCampaigns, referrer)
        );
    }

//    function getTotalDistributedInCycle(
//        uint cycleId
//    )
//    public
//    view
//    returns (uint)
//    {
//        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_distributionCycle2TotalDistributed, cycleId));
//    }

//    function addNewDistributionCycle()
//    internal
//    returns (uint)
//    {
//        bytes32 key = keccak256(_numberOfCycles);
//
//        uint incrementedNumberOfCycles = PROXY_STORAGE_CONTRACT.getUint(key) + 1;
//
//        PROXY_STORAGE_CONTRACT.setUint(
//            key,
//            incrementedNumberOfCycles
//        );
//
//        return incrementedNumberOfCycles;
//    }

    function deleteReferrerPendingCampaigns(
        bytes32 key
    )
    internal
    {
        deleteAddressArray(key);
    }

    /**
     * @notice          Function to delete address array for specific influencer
     */
    function deleteAddressArray(
        bytes32 key
    )
    internal
    {
        address [] memory emptyArray = new address[](0);
        PROXY_STORAGE_CONTRACT.setAddressArray(key, emptyArray);
    }

//    function setReferrerRebalancedTotalPayout(
//        address referrer,
//        uint amount
//    )
//    internal
//    {
//        PROXY_STORAGE_CONTRACT.setUint(
//            keccak256(_referrer2rebalancedTotalPayout, referrer),
//            amount
//        );
//    }

//    function setTotalRebalancedPayoutForCycle(
//        uint cycleId,
//        uint totalRebalancedPayout
//    )
//    internal
//    {
//        PROXY_STORAGE_CONTRACT.setUint(
//            keccak256(_distributionCycleToTotalRebalancedPayment, cycleId),
//            totalRebalancedPayout
//        );
//    }

//    function setTotalNonRebalancedPayoutForCycle(
//        uint cycleId,
//        uint totalNonRebalancedPayout
//    )
//    internal
//    {
//        PROXY_STORAGE_CONTRACT.setUint(
//            keccak256(_distributionCycle2TotalNonRebalancedPayment, cycleId),
//            totalNonRebalancedPayout
//        );
//    }

//    function setReferrersPaidPerDistributionCycle(
//        uint cycleId,
//        address [] referrers
//    )
//    internal
//    {
//        PROXY_STORAGE_CONTRACT.setAddressArray(
//            keccak256(_distributionCycleIdToReferrersPaid, cycleId),
//            referrers
//        );
//    }


//    /**
//     * @notice          Function to get exact amount of distribution cycles
//     */
//    function getNumberOfDistributionCycles()
//    public
//    view
//    returns (uint)
//    {
//        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfCycles));
//    }

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
        uint [],
        bool []
    )
    {
            // Address types
            // Gets campaigns contractor
            address contractorAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma));

            // Uint types
            uint [] uintValues;
            // Gets leftover for contractor
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignAddressPlasma)));
            // Gets campaigns total budget in 2KEY
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma)));
            // Gets campaigns total budget in USD
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma)));
            // Gets bounty per conversion in 2KEY
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignAddressPlasma)));
            // Gets bounty per conversion in USD
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2bountyPerConversionUSD, campaignAddressPlasma)));
            // Gets total referrer rewards
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignAddressPlasma)));
            // Gets moderator earnings
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2ModeratorEarnings, campaignAddressPlasma)));

            // Boolean types
            bool [] booleanValues;
            // Gets boolean value if campaign is budgeted directly with 2Key currency
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma)));
            // Gets is campaign ended
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isCampaignEnded, campaignAddressPlasma)));
            // Gets is leftover withdrawn by contractor
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignAddressPlasma)));
        // Returns address of the contractor and two arrays (array of uint values and array of boolean values)
        return(
            contractorAddress,
            uintValues,
            booleanValues
        );
    }
}
