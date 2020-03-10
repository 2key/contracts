pragma solidity ^0.4.24;

import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "./TwoKeyPlasmaCampaign.sol";
import "../TwoKeyConversionStates.sol";


contract TwoKeyCPCCampaignPlasma is UpgradeableCampaign, TwoKeyPlasmaCampaign, TwoKeyConversionStates {

    string public targetUrl;            // Url being tracked

    /**
     * This is the conversion object
     * converterPlasma is the address of converter
     * bountyPaid is the bounty paid for that conversion
     * conversionTimestamp is the timestamp of a block in which conversion happened
     * state is the current state of conversion, implements enum ConversionState
     */
    struct Conversion {
        address converterPlasma;
        uint bountyPaid;
        uint conversionTimestamp;
        ConversionState state;
    }

    Conversion [] conversions;          // Array of all conversions

    function setInitialParamsCPCCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        address _moderator,
        string _url,
        uint [] numberValues
    )
    public
    {
        require(isCampaignInitialized == false);                        // Requiring that method can be called only once
        isCampaignInitialized = true;                                   // Marking campaign as initialized

        TWO_KEY_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;    // Assigning address of _twoKeyPlasmaSingletonRegistry
        contractor = _contractor;                                       // Assigning address of contractor
        moderator = _moderator;                                         // Assigning address of moderator
        targetUrl = _url;                                               // Set the URL being tracked for the campaign
        contractorPublicAddress = ethereumOf(_contractor);              // Set contractor contractorPublicAddress
        campaignStartTime = numberValues[0];                            // Set when campaign starts
        campaignEndTime = numberValues[1];                              // Set when campaign ends
        conversionQuota = numberValues[2];                              // Set conversion quota
        totalSupply_ = numberValues[3];                                 // Set total supply
        incentiveModel = IncentiveModel(numberValues[4]);               // Set the incentiveModel selected for the campaign
        bountyPerConversionWei = numberValues[5];                       // Set the bountyPerConversionWei amount
        received_from[_contractor] = _contractor;                       // Set that contractor has joined from himself
        balances[_contractor] = totalSupply_;                           // Set balance of arcs for contractor to totalSupply

        counters = new uint[](8);                                       // Initialize array of counters

    }


    function convert(
        bytes signature
    )
    contractNotLocked
    isCampaignValidated
    public
    {
        // Require that this is his first conversion
        require(isConverter(msg.sender) == false);
        // Save converter signature on the blockchain
        converterToSignature[msg.sender] = signature;

        // Create conversion
        Conversion memory c = Conversion(
            msg.sender,
            0,
            block.timestamp,
            ConversionState.PENDING_APPROVAL
        );

        // Get the ID and update mappings
        uint conversionId = conversions.length;
        conversions.push(c);
        converterToConversionId[msg.sender] = conversionId;
        counters[0]++; //Increase number of pending converters and conversions
        counters[3]++; //Increase number of pending conversions

        //Emit conversion event through TwoKeyPlasmaEvents
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitConversionCreatedEvent(
            mirrorCampaignOnPublic,
            conversionId,
            contractor,
            msg.sender
        );
    }


    /**
     * @notice          Function to approve converter and execute conversion, can be called once per converter
     * @param           converter is the plasma address of the converter
     */
    function approveConverterAndExecuteConversion(
        address converter
    )
    public
    contractNotLocked
    onlyMaintainer
    isCampaignValidated
    {
        //Check if converter don't have any executed conversions before and approve him
        oneTimeApproveConverter(converter);
        // Require that no more than maxNumberOfConversions can be approved
        require(counters[5] < maxNumberOfConversions);
        // Get the converter signature
        bytes memory signature = converterToSignature[converter];
        // Distribute arcs if necessary
        distributeArcsIfNecessary(converter, signature);
        //Get the conversion id
        uint conversionId = converterToConversionId[converter];
        // Get the conversion object
        Conversion storage c = conversions[conversionId];
        // Update state of conversion to EXECUTED
        c.state = ConversionState.EXECUTED;

        // If the conversion is not directly from the contractor and there's enough rewards for this conversion we will distribute them
        if(getNumberOfUsersToContractor(converter) > 0 && counters[6].add(bountyPerConversionWei) <= totalBountyForCampaign) {
            //Get moderator fee percentage
            uint moderatorFeePercent = getModeratorFeePercent();
            //Calculate moderator fee to be taken from bounty
            uint moderatorFee = bountyPerConversionWei.mul(moderatorFeePercent).div(100);
            //Add earnings to moderator total earnings
            moderatorTotalEarnings = moderatorTotalEarnings.add(moderatorFee);
            //Left to be distributed between influencers
            uint bountyToBeDistributed = bountyPerConversionWei.sub(moderatorFee);
            //Distribute rewards between referrers
            updateRewardsBetweenInfluencers(converter, conversionId, bountyToBeDistributed);
            //Update paid bounty
            c.bountyPaid = bountyToBeDistributed;
            //Increment how much bounty is paid
            counters[6] = counters[6] + bountyToBeDistributed; // Total bounty paid
        }

        counters[0]--; //Decrement number of pending converters
        counters[1]++; //increment number approved converters
        counters[3]--; // Decrement number of pending conversions
        counters[5]++; //increment number of executed conversions

        //Emit event through TwoKeyEventSource that conversion is approved and executed
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitConversionExecutedEvent(
            conversionId
        );
    }


    function rejectConverterAndConversion(
        address converter
    )
    public
    contractNotLocked
    onlyMaintainer
    isCampaignValidated
    {
        require(isApprovedConverter[converter] == false);

        // Get the conversion ID
        uint conversionId = converterToConversionId[converter];

        // Get the conversion object
        Conversion storage c = conversions[conversionId];

        require(c.state == ConversionState.PENDING_APPROVAL);
        c.state = ConversionState.REJECTED;

        counters[0]--; //reduce number of pending converters
        counters[2]++; //increase number of rejected converters
        counters[3]--; //reduce number of pending conversions
        counters[4]++; //increase number of rejected conversions
    }

    function getConversion(
        uint _conversionId
    )
    public
    view
    returns (address, uint, uint, ConversionState)
    {
        Conversion memory c = conversions[_conversionId];
        return (
            c.converterPlasma,
            c.bountyPaid,
            c.conversionTimestamp,
            c.state
        );
    }

}
