pragma solidity ^0.4.0;

import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "./TwoKeyPlasmaAffiliationCampaignAbstract.sol";

contract TwoKeyPlasmaAffiliationCampaign is UpgradeableCampaign, TwoKeyPlasmaAffiliationCampaignAbstract {

    /**
     * This is the conversion object
     * converterPlasma is the address of converter
     * bountyPaid is the bounty paid for that conversion
     */
    struct Conversion {
        address converterPlasma;
        uint bountyPaid;
        uint conversionTimestamp;
    }

    Conversion [] conversions;          // Array of all conversions

    function setInitialParamsAffiliationCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        uint [] numberValues
    )
    public
    {
        require(isCampaignInitialized == false);                        // Requiring that method can be called only once
        isCampaignInitialized = true;                                   // Marking campaign as initialized

        TWO_KEY_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;    // Assigning address of _twoKeyPlasmaSingletonRegistry
        contractor = _contractor;                                       // Assigning address of contractor
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
     * @param           bountyAdded is bounty contractor added more to the campaign
     */
    function extendCampaignBudget(
        uint bountyAdded
    )
    public
    onlyMaintainer
    {
        totalBountyAddedForCampaign = totalBountyAddedForCampaign.add(bountyAdded);
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
     */
    function registerConversion(
        address converter,
        bytes signature,
        uint amountOfTokensToDistribute
    )
    public
    onlyMaintainer
    isSubscriptionActive
    {

        // Check if there's enough bounty on the contract
        require(isThereEnoughBounty(amountOfTokensToDistribute));

        // Mark user that he's converter
        isConverter[converter] = true;

        // Create conversion
        Conversion memory c = Conversion(
            msg.sender,
            amountOfTokensToDistribute,
            block.timestamp
        );

        // Get the ID and update mappings
        uint conversionId = conversions.length;

        // Push conversion to array of successful conversions
        conversions.push(c);

        // Distribute arcs if necessary
        distributeArcsIfNecessary(converter,signature);


        // Bounty is getting distributed only if conversion is not directly from contractor
        if(getNumberOfUsersToContractor(converter) > 0) {

        } else {

        }

    }

}
