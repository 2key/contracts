pragma solidity ^0.4.0;

import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "./TwoKeyPlasmaAffiliationCampaignAbstract.sol";

contract TwoKeyPlasmaAffiliationCampaign is UpgradeableCampaign, TwoKeyPlasmaAffiliationCampaignAbstract {

    string public url;
    address public rewardsTokenAddress;

    /**
     * This is the conversion object
     * converterPlasma is the address of converter
     * bountyPaid is the bounty paid for that conversion
     */
    struct Conversion {
        address converterPlasma;
        uint bountyPaid;
        uint conversionTimestamp;
        string conversionType;
    }

    Conversion [] public conversions;          // Array of all conversions


    function setInitialParamsAffiliationCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        string _url,
        uint [] numberValues
    )
    public
    {
        require(isCampaignInitialized == false);                        // Requiring that method can be called only once
        isCampaignInitialized = true;                                   // Marking campaign as initialized

        TWO_KEY_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;    // Assigning address of _twoKeyPlasmaSingletonRegistry
        contractor = _contractor;                                       // Assigning address of contractor
        url = _url;                                                     // URL for the affiliation action
        campaignStartTime = numberValues[0];                            // Set when campaign starts
        campaignEndTime = numberValues[1];                              // Set when campaign ends
        conversionQuota = numberValues[2];                              // Set conversion quota
        totalSupply_ = numberValues[3];                                 // Set total supply
        incentiveModel = IncentiveModel(numberValues[4]);               // Set the incentiveModel selected for the campaign
        received_from[_contractor] = _contractor;                       // Set that contractor has joined from himself
        balances[_contractor] = totalSupply_;                           // Set balance of arcs for contractor to totalSupply
    }


    /**
     * @notice          Function to extend campaign budget. Maintainer calls it
     *                  when contractor adds more budget on public chain contract
     * @param           newTotalBounty is bounty contractor added more to the campaign
     */
    function extendCampaignBudget(
        uint newTotalBounty
    )
    public
    onlyMaintainer
    {
        require(newTotalBounty >= totalBountyAddedForCampaign);
        totalBountyAddedForCampaign = newTotalBounty;
    }



    /**
     * @notice          Function to extend subscription. Once subscription is ended and paid
     *                  again, maintainer will submit new subscription end date to public chain
     * @param           newEndDate is the new ending date of subscription
     */
    function extendSubscription(
        uint newEndDate
    )
    public
    onlyMaintainer
    {
        subscriptionEndDate = newEndDate;
    }


    /**
     * @notice          Function to set rewards token address for the campaign
     * @param           _rewardsTokenAddress is the address of rewards token
     */
    function setRewardsTokenAddress(
        address _rewardsTokenAddress
    )
    public
    onlyMaintainer
    {
        require(rewardsTokenAddress == address(0));
        rewardsTokenAddress = _rewardsTokenAddress;
    }


    /**
     * @notice          Function where maintainer will register conversion
     * @param           converter is converter plasma address
     * @param           signature is referral hash for this conversion
     * @param           amountOfTokensToDistribute is amount of tokens to distribute
     *                  between influencers in case there's at least one referrer
     *                  between contractor and converter.
     */
    function registerConversion(
        address converter,
        bytes signature,
        uint amountOfTokensToDistribute,
        string conversionType
    )
    external
    onlyMaintainer
    isSubscriptionActive
    isCampaignNotEnded
    isCampaignValidated
    {
        // Mark user that he's converter
        isConverter[converter] = true;
        // Create conversion
        Conversion memory c = Conversion(
            msg.sender,
            0,
            block.timestamp,
            conversionType
        );
        // Get the ID and update mappings
        uint conversionId = conversions.length;
        // Distribute arcs if necessary
        uint numberOfUsersInReferralChain = distributeArcsIfNecessary(converter,signature);
        // Bounty is getting distributed only if conversion is not directly from contractor
        if(getNumberOfUsersToContractor(converter) > 0) {
            // Check if there's enough bounty on the contract
            require(isThereEnoughBounty(amountOfTokensToDistribute));
            // Add bounty only if there's at least 1 influencer in this referral chain
            c.bountyPaid = amountOfTokensToDistribute;
            // Add bounty paid
            totalBountyDistributedForCampaign = totalBountyDistributedForCampaign.add(amountOfTokensToDistribute);

            // Emit event everytime there's paid conversion
            ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
                .emitConversionRegistered(
                    c.bountyPaid,
                    numberOfUsersInReferralChain,
                    rewardsTokenAddress
                );
        } else {
            // In other case there's no bounty to be paid for this conversion
            c.bountyPaid = 0;
        }
        // Update reputation points on conversion executed event
        updateReputationPointsOnConversionExecutedEvent(converter);
        //Distribute rewards between referrers
        updateRewardsBetweenInfluencers(converter, conversionId, c.bountyPaid);
        // Push conversion to array of successful conversions
        conversions.push(c);
    }


    /**
     * @notice          Function to return number of conversions
     */
    function getNumberOfConversions()
    public
    view
    returns (uint)
    {
        return conversions.length;
    }

}
