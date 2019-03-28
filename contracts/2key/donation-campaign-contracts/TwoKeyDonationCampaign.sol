pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";

import "../interfaces/ITwoKeyDonationConversionHandler.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyCampaign, TwoKeyCampaignIncentiveModels, TwoKeyConverterStates, TwoKeyConversionStates {

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


    modifier isOngoing {
        require(now >= campaignStartTime && now <= campaignEndTime);
        _;
    }

    modifier onlyInDonationLimit {
        require(msg.value >= minDonationAmountWei && msg.value <= maxDonationAmountWei);
        _;
    }

    modifier goalValidator {
        if(campaignGoal != 0) {
            require(this.balance.add(msg.value) <= campaignGoal);
        }
        _;
    }



    constructor(
        address _moderator,
        string _campaignName,
        uint [] values,
        bool _shouldConvertToReffer,
        bool _isKYCRequired,
        bool _acceptsFiat,
        address _twoKeySingletonesRegistry,
        address _twoKeyDonationConversionHandler,
        IncentiveModel _rewardsModel
    ) public {
        // Moderator address
        moderator = _moderator;
        campaignName = _campaignName;

        if(values[0] == 0) {
            rewardsModel = IncentiveModel.NO_REWARDS;
        } else {
            rewardsModel = _rewardsModel;
        }

        acceptsFiat = _acceptsFiat;
        campaignStartTime = values[1];
        campaignEndTime = values[2];
        minDonationAmountWei = values[3];
        maxDonationAmountWei = values[4];
        campaignGoal = values[5];
        conversionQuota = values[6];

        twoKeyDonationConversionHandler = _twoKeyDonationConversionHandler;
        ITwoKeyDonationConversionHandler(_twoKeyDonationConversionHandler).
            setTwoKeyDonationCampaign(address(this), _isKYCRequired, values[0]);

        shouldConvertToRefer = _shouldConvertToReffer;
        isKYCRequired = _isKYCRequired;

        twoKeySingletonesRegistry = _twoKeySingletonesRegistry;
        contractor = msg.sender;
        twoKeyEventSource = TwoKeyEventSource(ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyEventSource"));
        ownerPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;
    }


    /**
     * @notice Function to unpack signature and distribute arcs so we can keep trace on referrals
     * @param signature is the signature containing the whole refchain up to the user
     */
    function distributeArcsBasedOnSignature(bytes signature) internal {
        address[] memory influencers;
        address[] memory keys;
        address old_address;
        (influencers, keys,, old_address) = super.getInfluencersKeysAndWeightsFromSignature(signature);
        uint i;
        address new_address;
        // move ARCs based on signature information
        // TODO: Handle failing of this function if the referral chain is too big
        uint numberOfInfluencers = influencers.length;
        for (i = 0; i < numberOfInfluencers; i++) {
            //Validate that the user is converter in order to join
            if(shouldConvertToRefer == true) {
                address eth_address_influencer = twoKeyEventSource.ethereumOf(influencers[i]);
                require(amountUserContributed[eth_address_influencer] > 0);
            }
            new_address = twoKeyEventSource.plasmaOf(influencers[i]);
            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }
            old_address = new_address;

            if (i < keys.length) {
                setPublicLinkKeyOf(new_address, keys[i]);
            }
        }
    }

    function updateContractorBalanceAndConverterDonations(
        address _converter,
        uint earningsContractor,
        uint donationsConverter
    ) public {
        require(msg.sender == twoKeyDonationConversionHandler);
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
    //TODO: Add modifier onlyDonationConversionHandler
    function distributeReferrerRewards(address converter, uint referrer_rewards, uint donationId) public returns (uint) {
        require(msg.sender == twoKeyDonationConversionHandler);
        address[] memory referrers = getReferrers(converter);
        uint numberOfReferrers = referrers.length;

        //Buy amount of 2key tokens for rewards
        uint totalBountyTokens = buyTokensFromUpgradableExchange(referrer_rewards, address(this));

        //Distribute rewards based on model selected
        if(rewardsModel == IncentiveModel.AVERAGE) {
            uint reward = IncentiveModels.averageModelRewards(totalBountyTokens, numberOfReferrers);
            for(uint i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], reward, donationId);
            }
        } else if(rewardsModel == IncentiveModel.AVERAGE_LAST_3X) {
            uint rewardPerReferrer;
            uint rewardForLast;
            (rewardPerReferrer, rewardForLast)= IncentiveModels.averageLast3xRewards(totalBountyTokens, numberOfReferrers);
            for(i=0; i<numberOfReferrers - 1; i++) {
                updateReferrerMappings(referrers[i], rewardPerReferrer, donationId);
            }
            updateReferrerMappings(referrers[numberOfReferrers-1], rewardForLast, donationId);
        } else if(rewardsModel == IncentiveModel.POWER_LAW) {
            uint[] memory rewards = IncentiveModels.powerLawRewards(totalBountyTokens, numberOfReferrers, powerLawFactor);
            for(i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], rewards[i], donationId);
            }
        }

        return totalBountyTokens;
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature generatedD
     * @param receiver is the address we're sending ARCs to
     */
    function joinAndShareARC(bytes signature, address receiver) public {
        distributeArcsBasedOnSignature(signature);
        transferFrom(twoKeyEventSource.plasmaOf(msg.sender), twoKeyEventSource.plasmaOf(receiver), 1);
    }

    /**
     * @notice Function where user can join to campaign and donate funds
     * @param signature is signature he's joining with
     */
    //TOOO: Get back modifiers isOngoing
    function joinAndDonate(bytes signature) public goalValidator onlyInDonationLimit payable {
        distributeArcsBasedOnSignature(signature);
        ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).createDonation(msg.sender, msg.value);
    }

    /**
     * @notice Function where user has already joined and want to donate
     */
    function donate() public goalValidator onlyInDonationLimit isOngoing payable {
        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        require(received_from[_converterPlasma] != address(0));
        ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).createDonation(msg.sender, msg.value);
    }

    function convertFiat() public goalValidator onlyInDonationLimit {

    }

    /**
     * @notice Fallback function to handle input payments -> no referrer rewards in this case
     */
    function () goalValidator onlyInDonationLimit isOngoing payable {
        //TODO: What is the requirement just to donate money
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
     * @param _donator is the one who sent money to the contract
     */
    function getAmountUserDonated(address _donator) public view returns (uint) {
        require(
            msg.sender == contractor ||
            msg.sender == _donator ||
            twoKeyEventSource.isAddressMaintainer(msg.sender)
        );

        return amountUserContributed[_donator];
    }

    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[_referrer];
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

    /**
     * @notice Function interface for moderator or referrer to withdraw their earnings
     * @param _address is the one who wants to withdraw
     */
    function withdrawModeratorOrReferrer(address _address) public {
        require(this.balance >= campaignGoal); //Making sure goal is reached
        require(block.timestamp > campaignEndTime); //Making sure time has expired
        require(msg.sender == _address);

        super.withdrawModeratorOrReferrer(_address);
    }

}
