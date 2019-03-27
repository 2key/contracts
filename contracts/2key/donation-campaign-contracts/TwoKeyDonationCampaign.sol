pragma solidity ^0.4.24;

import "./InvoiceTokenERC20.sol";

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyCampaign, TwoKeyCampaignIncentiveModels, TwoKeyConverterStates, TwoKeyConversionStates {

    event InvoiceTokenCreated(address token, string tokenName, string tokenSymbol);
    address public erc20InvoiceToken; // ERC20 token which will be issued as an invoice

    uint powerLawFactor = 2;

    string campaignName; // Name of the campaign
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmountWei; // Minimal donation amount
    uint maxDonationAmountWei; // Maximal donation amount
    uint maxReferralRewardPercent; // Percent per conversion which goes to referrers
    uint campaignGoal; // Goal of the campaign, how many funds to raise
    bool shouldConvertToRefer; // If yes, means that referrer must be converter in order to be referrer
    bool isKYCRequired; // Will determine if KYC is required or not
    IncentiveModel rewardsModel; //Incentive model for rewards

    mapping(address => uint) amountUserContributed; //If amount user contributed is > 0 means he's a converter
    mapping(address => uint[]) converterToConversionIDs;

    //Referral accounting stuff
    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;


    //Converter to his state
    mapping(address => ConverterState) converterToState;

    DonationEther[] donations;


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

    //Struct to represent donation in Ether
    struct DonationEther {
        address donator; //donator -> address who donated
        uint amount; //donation amount ETH
        uint contractorProceeds; // Amount which can be taken by contractor
        uint donationTimestamp; // When was donation created
        uint totalBountyEthWei; // Rewards amount in ether
        uint totalBounty2keyWei; // Rewards distributed between referrers for this campaign in 2key-tokens
        ConversionState state;
    }

    constructor(
        address _moderator,
        string _campaignName,
        string tokenName,
        string tokenSymbol,
        uint [] values,
        bool _shouldConvertToReffer,
        bool _isKYCRequired,
        address _twoKeySingletonesRegistry,
        IncentiveModel _rewardsModel
    ) public {
        // Deploy an ERC20 token which will be used as the Invoice
        erc20InvoiceToken = new InvoiceTokenERC20(tokenName,tokenSymbol,address(this));

        // Emit an event with deployed token address, name, and symbol
        emit InvoiceTokenCreated(erc20InvoiceToken, tokenName, tokenSymbol);

        // Moderator address
        moderator = _moderator;
        campaignName = _campaignName;

        if(values[0] == 0) {
            rewardsModel = IncentiveModel.NO_REWARDS;
        } else {
            rewardsModel = _rewardsModel;
        }
        maxReferralRewardPercent = values[0];
        campaignStartTime = values[1];
        campaignEndTime = values[2];
        minDonationAmountWei = values[3];
        maxDonationAmountWei = values[4];
        campaignGoal = values[5];
        conversionQuota = values[6];

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
    function distributeReferrerRewards(address converter, uint referrer_rewards, uint donationId) internal returns (uint) {
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
    //TOOO: Get bakc modifiers isOngoing
    function joinAndDonate(bytes signature) public goalValidator onlyInDonationLimit payable {
        distributeArcsBasedOnSignature(signature);
        createDonation(msg.sender, msg.value);
    }

    /**
     * @notice Function where user has already joined and want to donate
     */
    function donate() public goalValidator onlyInDonationLimit isOngoing payable {
        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        require(received_from[_converterPlasma] != address(0));

        createDonation(msg.sender, msg.value);
    }

    /**
     * @notice Function where contractor can update power law factor for the rewards
     */
    function updatePowerLawFactor(uint _newPowerLawFactor) public onlyContractor {
        require(_newPowerLawFactor> 0);

        powerLawFactor = _newPowerLawFactor;
    }

    /**
     * @notice Fallback function to handle input payments -> no referrer rewards in this case
     */
    function () goalValidator onlyInDonationLimit isOngoing payable {
        //TODO: What is the requirement just to donate money
    }

    function getAmountUserDonated(address _donator) public view returns (uint) {
        require(
            msg.sender == contractor ||
            msg.sender == _donator ||
            twoKeyEventSource.isAddressMaintainer(msg.sender)
        );

        return amountUserContributed[_donator];
    }

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
     * @notice Function to read donation
     * @param donationId is the id of donation
     */
    function getDonation(uint donationId) public view returns (bytes) {
        DonationEther memory donation = donations[donationId];

        return abi.encodePacked(
            donation.donator,
            donation.amount,
            donation.contractorProceeds,
            donation.donationTimestamp,
            donation.totalBountyEthWei,
            donation.totalBounty2keyWei,
            donation.state
        );
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
     * @notice Function to get rewards model present in contract for referrers
     * @return position of the model inside enum IncentiveModel
     */
    function getIncentiveModel() public view returns (IncentiveModel) {
        return rewardsModel;
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

    /**
     * @param _converter is the one who calls join and donate function
     * @param _donationAmount is the amount to be donated
     */
    function createDonation(address _converter, uint _donationAmount) internal {
        //Basic accounting stuff
        // Calculate referrer rewards in ETH based on conversion amount
        uint referrerReward = (_donationAmount).mul(maxReferralRewardPercent).div(100 * (10**18));

        uint contractorProceeds = _donationAmount - referrerReward;

        // Create object for this donation
        DonationEther memory donation = DonationEther(_converter, _donationAmount, contractorProceeds, block.timestamp, referrerReward, 0, ConversionState.PENDING_APPROVAL);

        // Get donation ID
        uint id = donations.length;

        // Save amount donator contributed in total (donated)
        amountUserContributed[_converter] += _donationAmount; // user contributions

        // Add donation id under donator id's
        converterToConversionIDs[_converter].push(id); // accounting for the donator

        // If KYC is not required or converter is approved
        if(isKYCRequired == false || converterToState[_converter] == ConverterState.APPROVED) {

            // If there's a reward for influencers, distribute it between them
            if(referrerReward > 0) {
                uint totalBountyTokens = distributeReferrerRewards(_converter, referrerReward, id);
                donation.totalBounty2keyWei = totalBountyTokens;
            }

            donation.state = ConversionState.EXECUTED;

            // Add donation to array of all donations
            donations.push(donation);

            // Transfer invoice token to donator (Contributor)
            InvoiceTokenERC20(erc20InvoiceToken).transfer(_converter, _donationAmount);

            // Update that donator is approved (since KYC is false every donator will be approved)
            converterToState[_converter] = ConverterState.APPROVED;

            // Contractor balance is automatically updated
            contractorBalance = contractorBalance.add(contractorProceeds);
        } else {

            if(converterToState[_converter] == ConverterState.REJECTED) {
                revert();
            }

            if(converterToState[_converter] == ConverterState.NOT_EXISTING) {
                // Handle converter to wait for approval
                converterToState[_converter] = ConverterState.PENDING_APPROVAL;

                // Add donation to array of all donations
                donations.push(donation);
            }
        }
    }


    function approveConverter(address _converter) public onlyContractor {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);

        uint[] memory conversionIds = converterToConversionIDs[_converter];

        for(uint i=0; i<conversionIds.length; i++) {
            DonationEther storage don = donations[conversionIds[i]];
            if(don.state == ConversionState.PENDING_APPROVAL) {
                don.totalBounty2keyWei = distributeReferrerRewards(_converter, don.totalBountyEthWei, conversionIds[i]);
                contractorBalance = contractorBalance.add(don.contractorProceeds);
                don.state = ConversionState.EXECUTED;
            }
        }
        converterToState[_converter] = ConverterState.APPROVED;
    }

    function rejectConverter(address _converter) public onlyContractor {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);

        uint[] memory conversionIds = converterToConversionIDs[_converter];
        uint refundAmount = 0;

        for(uint i=0; i<conversionIds.length; i++) {
            DonationEther storage d = donations[conversionIds[i]];
            if(d.state == ConversionState.PENDING_APPROVAL) {
                refundAmount = refundAmount.add(d.amount);
                d.state = ConversionState.REJECTED;
            }
        }

        if(refundAmount > 0) {
            _converter.transfer(refundAmount);
        }
    }
}
