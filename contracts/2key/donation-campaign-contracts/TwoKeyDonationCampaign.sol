pragma solidity ^0.4.24;

import "./TwoKeyDonationCampaignType.sol";
import "./InvoiceTokenERC20.sol";

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../libraries/IncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyDonationCampaignType, TwoKeyCampaign, TwoKeyCampaignIncentiveModels {

    DonationType campaignType; //Type of campaign

    string campaignName; // Name of the campaign
    string publicMetaHash; // Ipfs hash of public informations
    string privateMetaHash; //TODO: Is there a need for private
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmount; // Minimal donation amount
    uint maxDonationAmount; // Maximal donation amount
    uint campaignGoal; // Goal of the campaign, how many funds to raise
    IncentiveModel rewardsModel; //Incentive model for rewards
    address erc20InvoiceToken; // ERC20 token which will be issued as an invoice
    uint maxReferralRewardPercent; // Percent per conversion which goes to referrers

    uint donationsBalance; // Balance earned by donations -> locked

    mapping(address => uint) amountUserContributed;

    mapping(address => uint[]) donatorToHisDonationsInEther;
    uint numberOfDonationsEther;
    DonationEther[] donationsEther;


    modifier isOngoing {
        require(now >= campaignStartTime && now <= campaignEndTime);
        _;
    }


    modifier onlyInDonationLimit {
        require(msg.value >= minDonationAmount && msg.value <= maxDonationAmount);
        _;
    }

    modifier goalValidator {
        if(campaignGoal != 0) {
            require(donationsBalance.add(msg.value) <= campaignGoal);
        }
        _;
    }

    struct DonationEther {
        address donator;
        uint amount;
        uint donationTimestamp;
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
        IncentiveModel _rewardsModel
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
        // Calculating manual stuff
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
        return influencers; //reverse ordered array
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
        amountUserContributed[msg.sender] += msg.value;
    }

    /**
     * @notice Function where user has already joined and want to donate
     */
    function donate() public goalValidator onlyInDonationLimit isOngoing payable {
        amountUserContributed[msg.sender] += msg.value;
    }

    /**
     * @notice Fallback function to handle input payments -> no referrer rewards in this case
     */
    function () goalValidator onlyInDonationLimit isOngoing payable {
    }

    /**
     * @notice Function to read donation
     * @param donationId is the id of donation
     */
    function getDonation(uint donationId) public view returns (bytes) {
        DonationEther memory donation = donationsEther[donationId];
        return abi.encodePacked(donation.donator, donation.amount, donation.donationTimestamp);
    }
}
