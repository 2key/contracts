pragma solidity ^0.4.24;

import "./InvoiceTokenERC20.sol";

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../libraries/IncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyCampaign, TwoKeyCampaignIncentiveModels {

    address public erc20InvoiceToken; // ERC20 token which will be issued as an invoice

    uint powerLawFactor = 2;

    string campaignName; // Name of the campaign
    string publicMetaHash; // Ipfs hash of public informations
    string privateMetaHash; //TODO: Is there a need for private
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmount; // Minimal donation amount
    uint maxDonationAmount; // Maximal donation amount
    uint maxReferralRewardPercent; // Percent per conversion which goes to referrers
    uint campaignGoal; // Goal of the campaign, how many funds to raise
    IncentiveModel rewardsModel; //Incentive model for rewards

    mapping(address => uint) amountUserContributed;
    mapping(address => uint[]) donatorToHisDonationsInEther;
    DonationEther[] donations;


    modifier isOngoing {
        require(now >= campaignStartTime && now <= campaignEndTime, "Campaign expired or not started yet");
        _;
    }

    modifier onlyInDonationLimit {
        require(msg.value >= minDonationAmount && msg.value <= maxDonationAmount, "Wrong contribution amount");
        _;
    }

    modifier goalValidator {
        if(campaignGoal != 0) {
            require(this.balance.add(msg.value) <= campaignGoal,"Goal reached");
        }
        _;
    }

    struct DonationEther {
        address donator;
        uint amount;
        uint donationTimestamp;
        uint referrerRewards;
    }

    constructor(
        address _moderator,
        string _campaignName,
        string _publicMetaHash,
        string _privateMetaHash,
        string tokenName,
        string tokenSymbol,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _minDonationAmount,
        uint _maxDonationAmount,
        uint _campaignGoal,
        uint _conversionQuota,
        address _twoKeySingletonesRegistry,
        IncentiveModel _rewardsModel //Handled as uint on the FE
    ) public {
        erc20InvoiceToken = new InvoiceTokenERC20(tokenName,tokenSymbol,address(this));
        moderator = _moderator;
        campaignName = _campaignName;
        publicMetaHash = _publicMetaHash;
        privateMetaHash = _privateMetaHash;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        minDonationAmount = _minDonationAmount;
        maxDonationAmount = _maxDonationAmount;
        campaignGoal = _campaignGoal;
        conversionQuota = _conversionQuota;
        twoKeySingletonesRegistry = _twoKeySingletonesRegistry;
        rewardsModel = _rewardsModel;
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
            new_address = twoKeyEventSource.plasmaOf(influencers[i]);
            if (received_from[new_address] == 0) {
                transferFromInternal(old_address, new_address, 1);
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
    function updateReferrerMappings(address referrerPlasma, uint reward) internal {
        referrerPlasma2BalancesEthWEI[referrerPlasma] = reward;
        referrerPlasma2TotalEarningsEthWEI[referrerPlasma] += reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] += 1;
    }

    /**
     * @notice Function to distribute referrer rewards depending on selected model
     * @param converter is the address of the converter
     * @param totalBountyForConversion is total bounty for the conversion
     */
    function distributeReferrerRewards(address converter, uint totalBountyForConversion) internal {
        address[] memory referrers = getReferrers(converter);
        uint numberOfReferrers = referrers.length;
        if(rewardsModel == IncentiveModel.AVERAGE) {
            uint reward = IncentiveModels.averageModelRewards(totalBountyForConversion, numberOfReferrers);
            for(uint i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], reward);
            }
        } else if(rewardsModel == IncentiveModel.AVERAGE_LAST_3X) {
            uint rewardPerReferrer;
            uint rewardForLast;
            (rewardPerReferrer, rewardForLast)= IncentiveModels.averageLast3xRewards(totalBountyForConversion, numberOfReferrers);
            for(i=0; i<numberOfReferrers - 1; i++) {
                updateReferrerMappings(referrers[i], rewardPerReferrer);
            }
            updateReferrerMappings(referrers[numberOfReferrers-1], rewardForLast);
        } else if(rewardsModel == IncentiveModel.POWER_LAW) {
            uint[] memory rewards = IncentiveModels.powerLawRewards(totalBountyForConversion, numberOfReferrers, powerLawFactor);
            for(i=0; i<numberOfReferrers; i++) {
                updateReferrerMappings(referrers[i], rewards[i]);
            }
        }
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature generated
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
    function joinAndDonate(bytes signature) public goalValidator onlyInDonationLimit isOngoing payable {
        distributeArcsBasedOnSignature(signature);
        uint referrerReward = (msg.value).mul(maxReferralRewardPercent).div(100);
        DonationEther memory donation = DonationEther(msg.sender, msg.value, block.timestamp, referrerReward);
        uint id = donations.length; // get donation id
        donations.push(donation); // add donation to array of donations
        donatorToHisDonationsInEther[msg.sender].push(id); // accounting for the donator
        amountUserContributed[msg.sender] += msg.value;
    }

    /**
     * @notice Function where user has already joined and want to donate
     */
    function donate() public goalValidator onlyInDonationLimit isOngoing payable {
        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        require(received_from[_converterPlasma] != address(0));
        uint referrerReward = (msg.value).mul(maxReferralRewardPercent).div(100);
        DonationEther memory donation = DonationEther(msg.sender, msg.value, block.timestamp, referrerReward);
        uint id = donations.length; // get donation id
        donations.push(donation); // add donation to array of donations
        donatorToHisDonationsInEther[msg.sender].push(id); // accounting for the donator
        amountUserContributed[msg.sender] += msg.value;
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

    function getAmountUserContributed(address _donator) public view returns (uint) {
        require(
            msg.sender == contractor ||
            msg.sender == _donator ||
            twoKeyEventSource.isAddressMaintainer(msg.sender)
        );
        return amountUserContributed[_donator];
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
        return (referrerPlasma2BalancesEthWEI[_referrer], referrerPlasma2TotalEarningsEthWEI[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer], earnings);
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
            donation.donationTimestamp,
            donation.referrerRewards
        );
    }

    function getCampaignData() public view returns (bytes) {
        return abi.encodePacked(
            campaignStartTime,
            campaignEndTime,
            minDonationAmount,
            maxDonationAmount,
            maxReferralRewardPercent,
            campaignName,
            publicMetaHash,
            privateMetaHash
        );
    }
}
