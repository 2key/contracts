pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";

import "../interfaces/ITwoKeyDonationConversionHandler.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is UpgradeableCampaign, TwoKeyCampaign, TwoKeyCampaignIncentiveModels {

    bool initialized;

    address public twoKeyDonationConversionHandler; // Contract which will handle all donations

    uint powerLawFactor = 2;

    string campaignName; // Name of the campaign
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmountWei; // Minimal donation amount
    uint maxDonationAmountWei; // Maximal donation amount
    uint campaignGoal; // Goal of the campaign, how many funds to raise

    bool shouldConvertToRefer; // If yes, means that referrer must be converter in order to be referrer
    bool isKYCRequired; // Will determine if KYC is required or not
    bool acceptsFiat; // Will determine if fiat conversion can be created or not

    IncentiveModel rewardsModel; //Incentive model for rewards

    mapping(address => uint) amountUserContributed; //If amount user contributed is > 0 means he's a converter

    //Referral accounting stuff
    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;
    mapping(address => uint256) private referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address


    modifier onlyInDonationLimit {
        require(msg.value >= minDonationAmountWei && msg.value <= maxDonationAmountWei);
        _;
    }


    modifier onlyTwoKeyDonationConversionHandler {
        require(msg.sender == twoKeyDonationConversionHandler);
        _;
    }


    function setInitialParamsDonationCampaign(
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
        address _twoKeyDonationConversionHandler,
        uint [] numberValues,
        bool [] booleanValues,
        string _campaignName
    )
    public
    {
        require(initialized == false);

        contractor = _contractor;
        // Moderator address
        moderator = _moderator;
        campaignName = _campaignName;

        totalSupply_ = 1000000;

        rewardsModel = IncentiveModel(numberValues[7]);
        maxReferralRewardPercent = numberValues[0];
        campaignStartTime = numberValues[1];
        campaignEndTime = numberValues[2];
        minDonationAmountWei = numberValues[3];
        maxDonationAmountWei = numberValues[4];
        campaignGoal = numberValues[5];
        conversionQuota = numberValues[6];

        twoKeyDonationConversionHandler = _twoKeyDonationConversionHandler;

        //Set incentive model for the campaign
        rewardsModel = IncentiveModel(numberValues[7]);

        shouldConvertToRefer = booleanValues[0];
        isKYCRequired = booleanValues[1];
        acceptsFiat = booleanValues[2];

        twoKeySingletonesRegistry = _twoKeySingletonRegistry;
        twoKeyEventSource = TwoKeyEventSource(getContractProxyAddress("TwoKeyEventSource"));
        ownerPlasma = twoKeyEventSource.plasmaOf(_contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;


        initialized = true;
    }

    /**
      * @notice Function to set cut of
      * @param me is the address (ethereum)
      * @param cut is the cut value
      */
    function setCutOf(
        address me,
        uint256 cut
    )
    internal
    {
        // what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        address plasma = twoKeyEventSource.plasmaOf(me);
        require(referrerPlasma2cut[plasma] == 0 || referrerPlasma2cut[plasma] == cut);
        referrerPlasma2cut[plasma] = cut;
    }

    /**
     * @notice Function to set cut
     * @param cut is the cut value
     * @dev Executes internal setCutOf method
     */
    function setCut(
        uint256 cut
    )
    public
    {
        setCutOf(msg.sender, cut);
    }


    /**
     * @notice Function to get cut for an (ethereum) address
     * @param me is the ethereum address
     */
    function getReferrerCut(
        address me
    )
    public
    view
    returns (uint256)
    {
        return referrerPlasma2cut[twoKeyEventSource.plasmaOf(me)];
    }

    /**
     * @notice Function to track arcs and make ref tree
     * @param sig is the signature user joins from
     */
    function distributeArcsBasedOnSignature(
        bytes sig,
        address _converter
    )
    private
    {
        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address old_address;
        (influencers, keys, weights, old_address) = super.getInfluencersKeysAndWeightsFromSignature(sig, _converter);
        uint i;
        address new_address;
        uint numberOfInfluencers = influencers.length;
        for (i = 0; i < numberOfInfluencers; i++) {
            new_address = twoKeyEventSource.plasmaOf(influencers[i]);

            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }
            old_address = new_address;

            // TODO Updating the public key of influencers may not be a good idea because it will require the influencers to use
            // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
            // TODO a possible solution is change public_link_key to address=>address[]
            // update (only once) the public address used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < keys.length) {
                setPublicLinkKeyOf(new_address, keys[i]);
            }

            // update (only once) the cut used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < weights.length) {
                setCutOf(new_address, uint256(weights[i]));
            }
        }
    }


    /**
     * @notice Function which will buy tokens from upgradable exchange for moderator
     * @param moderatorFee is the fee in tokens moderator earned
     */
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public
    onlyTwoKeyDonationConversionHandler
    {
        //Get deep freeze token pool address
        address twoKeyDeepFreezeTokenPool = getContractProxyAddress("TwoKeyDeepFreezeTokenPool");

        uint networkFee = twoKeyEventSource.getTwoKeyDefaultNetworkTaxPercent();

        // Balance which will go to moderator
        uint balance = moderatorFee.mul(100-networkFee).div(100);

        uint moderatorEarnings2key = buyTokensFromUpgradableExchange(balance,moderator); // Buy tokens for moderator
        buyTokensFromUpgradableExchange(moderatorFee - balance, twoKeyDeepFreezeTokenPool); // Buy tokens for deep freeze token pool

        moderatorTotalEarnings2key = moderatorTotalEarnings2key.add(moderatorEarnings2key);
    }


    function updateContractorBalanceAndConverterDonations(
        address _converter,
        uint earningsContractor,
        uint donationsConverter
    )
    public
    {
        require(msg.sender == twoKeyDonationConversionHandler);

        contractorTotalProceeds = contractorTotalProceeds.add(earningsContractor);
        contractorBalance = contractorBalance.add(earningsContractor);
        amountUserContributed[_converter] = amountUserContributed[_converter].add(donationsConverter);
    }

    /**
     * @notice Internal function to update referrer mappings with value
     * @param referrerPlasma is referrer plasma address
     * @param reward is the reward referrer earned
     */
    function updateReferrerMappings(address referrerPlasma, uint reward, uint donationId) internal {
        referrerPlasma2Balances2key[referrerPlasma] = reward;
        referrerPlasma2TotalEarnings2key[referrerPlasma] += reward;
        referrerPlasma2EarningsPerConversion[referrerPlasma][donationId] = reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] += 1;
    }

    /**
     * @notice Function to distribute referrer rewards depending on selected model
     * @param converter is the address of the converter
     */
    function distributeReferrerRewards(
        address converter,
        uint referrer_rewards,
        uint donationId
    )
    public
//    onlyTwoKeyDonationConversionHandler
    returns (uint)
    {
        address[] memory referrers = getReferrers(converter);
        uint numberOfReferrers = referrers.length;

        //Buy amount of 2key tokens for rewards

        uint totalBountyTokens = buyTokensFromUpgradableExchange(referrer_rewards, address(this));

        reservedAmount2keyForRewards = reservedAmount2keyForRewards + totalBountyTokens;

        //Distribute rewards based on model selected
        if(rewardsModel == IncentiveModel.VANILLA_AVERAGE) {
            uint reward = IncentiveModels.averageModelRewards(totalBountyTokens, numberOfReferrers);
            for(uint i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], reward, donationId);
            }
        } else if(rewardsModel == IncentiveModel.VANILLA_AVERAGE_LAST_3X) {
            uint rewardPerReferrer;
            uint rewardForLast;
            (rewardPerReferrer, rewardForLast)= IncentiveModels.averageLast3xRewards(totalBountyTokens, numberOfReferrers);
            for(i=0; i<numberOfReferrers - 1; i++) {
                updateReferrerMappings(referrers[i], rewardPerReferrer, donationId);
            }
            updateReferrerMappings(referrers[numberOfReferrers-1], rewardForLast, donationId);
        } else if(rewardsModel == IncentiveModel.VANILLA_POWER_LAW) {
            uint[] memory rewards = IncentiveModels.powerLawRewards(totalBountyTokens, numberOfReferrers, powerLawFactor);
            for(i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], rewards[i], donationId);
            }
        } else if(rewardsModel == IncentiveModel.MANUAL) {
            uint totalBounty2keys = totalBountyTokens;
            for (i = 0; i < numberOfReferrers; i++) {
                uint256 b;

                if (i == referrers.length - 1) {  // if its the last influencer then all the bounty goes to it.
                    b = totalBounty2keys ;
                }
                else {
                    uint256 cut = getReferrerCut(referrers[i]);
                    if (cut > 0 && cut <= 101) {
                        b = totalBounty2keys.mul(cut.sub(1)).div(100);
                    } else {// cut == 0 or 255 indicates equal particine of the bounty
                        b = totalBounty2keys.div(referrers.length - i);
                    }
                }
                updateReferrerMappings(referrers[i], b, donationId);
                //Decrease bounty for distributed
                totalBounty2keys = totalBounty2keys.sub(b);
            }
        }
        return totalBountyTokens;
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature
     * @param receiver is the address we're sending ARCs to
     */
    function joinAndShareARC(
        bytes signature,
        address receiver
    )
    public
    {
        distributeArcsBasedOnSignature(signature, msg.sender);
        transferFrom(twoKeyEventSource.plasmaOf(msg.sender), twoKeyEventSource.plasmaOf(receiver), 1);
    }

    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convert(
        bytes signature
    )
    public
    payable
    {
        //TODO: Add validator if conversion can be made

        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        if(received_from[_converterPlasma] == address(0)) {
            distributeArcsBasedOnSignature(signature, msg.sender);
        }
        createConversion(msg.value, msg.sender);
        twoKeyEventSource.converted(address(this),msg.sender,msg.value);
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     */
    function createConversion(
        uint conversionAmountEthWEI,
        address converterAddress
    )
    private
    {
        //TODO: Add validator for donation goal
        uint256 maxReferralRewardFiatOrETHWei = conversionAmountEthWEI.mul(maxReferralRewardPercent).div(10**18).div(100);

        uint id = ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).supportForCreateConversion(
            converterAddress,
            conversionAmountEthWEI,
            maxReferralRewardFiatOrETHWei,
            isKYCRequired
        );

        if(isKYCRequired == false) {
            ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).executeConversion(id);
        }
    }

    /**
     * @notice Function which acts like getter for all cuts in array
     * @param last_influencer is the last influencer
     * @return array of integers containing cuts respectively
     */
    function getReferrerCuts(
        address last_influencer
    )
    public
    view
    returns (uint256[])
    {
        address[] memory influencers = getReferrers(last_influencer);
        uint256[] memory cuts = new uint256[](influencers.length + 1);

        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers; i++) {
            address influencer = influencers[i];
            cuts[i] = getReferrerCut(influencer);
        }
        cuts[influencers.length] = getReferrerCut(last_influencer);
        return cuts;
    }

    /**
     * @notice Function where contractor can update power law factor for the rewards
     */
    function updatePowerLawFactor(uint _newPowerLawFactor) public onlyContractor {
        require(_newPowerLawFactor> 0);

        powerLawFactor = _newPowerLawFactor;
    }

    /**
     * @notice Function to get all referrers participated in conversion
     * @param converter is the converter (one who did the action and ended ref chain)
     * @return array of addresses (plasma) of influencers
     */
    function getReferrers(address converter) public view returns (address[]) {
        address influencer = twoKeyEventSource.plasmaOf(converter);
        uint n_influencers = 0;
        while (true) {
            influencer = twoKeyEventSource.plasmaOf(received_from[influencer]);
            if (influencer == twoKeyEventSource.plasmaOf(contractor)) {
                break;
            }
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        influencer = twoKeyEventSource.plasmaOf(converter);
        while (n_influencers > 0) {
            influencer = twoKeyEventSource.plasmaOf(received_from[influencer]);
            n_influencers--;
            influencers[n_influencers] = influencer;
        }
        return influencers;
    }

    /**
     * @notice Function to get how much has user donated
     * @param _converter is the one who sent money to the contract
     */
    function getAmountUserDonated(address _converter) public view returns (uint) {
        require(
            msg.sender == contractor ||
            msg.sender == _converter ||
            twoKeyEventSource.isAddressMaintainer(msg.sender)
        );

        return amountUserContributed[_converter];
    }

    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[twoKeyEventSource.plasmaOf(_referrer)];
    }

    /**
    * @notice Function to fetch for the referrer his balance, his total earnings, and how many conversions he participated in
    * @dev only referrer by himself, moderator, or contractor can call this
    * @param _referrer is the address of referrer we're checking for
    * @param signature is the signature if calling functions from FE without ETH address
    * @param donationIds are the ids of conversions this referrer participated in
    * @return tuple containing this 3 information
    */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(address _referrer, bytes signature, uint[] donationIds) public view returns (uint,uint,uint,uint[]) {
        if(_referrer != address(0)) {
            require(msg.sender == _referrer || msg.sender == contractor || twoKeyEventSource.isAddressMaintainer(msg.sender));
            _referrer = twoKeyEventSource.plasmaOf(_referrer);
        } else {
            bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
                keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
            _referrer = Call.recoverHash(hash, signature, 0);
        }

        uint length = donationIds.length;
        uint[] memory earnings = new uint[](length);

        for(uint i=0; i<length; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrer][donationIds[i]];
        }

        return (referrerPlasma2Balances2key[_referrer], referrerPlasma2TotalEarnings2key[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer], earnings);
    }

    /**
     * @notice Function to get rewards model present in contract for referrers
     * @return position of the model inside enum IncentiveModel
     */
    function getIncentiveModel() public view returns (IncentiveModel) {
        return rewardsModel;
    }

    /**
     * @notice Contractor can withdraw funds only if criteria is satisfied
     */
    function withdrawContractor() public onlyContractor {
        require(this.balance >= campaignGoal); //Making sure goal is reached
        require(block.timestamp > campaignEndTime); //Making sure time has expired

        super.withdrawContractor();
    }

    function getReservedAmount2keyForRewards() public view returns (uint) {
        return reservedAmount2keyForRewards;
    }

}
