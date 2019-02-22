pragma solidity ^0.4.24;

import "./TwoKeyDonationCampaignType.sol";
import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyDonationCampaignType, TwoKeyCampaign {

    DonationType campaignType; //Type of campaign

    string campaignName; // Name of the campaign
    string publicMetaHash; // Ipfs hash of public informations
    string privateMetaHash; //TODO: Is there a need for private
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmount; // Minimal donation amount
    uint maxDonationAmount; // Maximal donation amount
    uint campaignGoal; // Goal of the campaign, how many funds to raise

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
        address _erc20InvoiceToken,
        address _moderator,
        string _campaignName,
        string _publicMetaHash,
        string _privateMetaHash,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _minDonationAmount,
        uint _maxDonationAmount,
        uint _campaignGoal,
        uint _conversionQuota,
        address _twoKeySingletonesRegistry
    ) public {
        contractor = msg.sender;
        moderator = _moderator;
        twoKeyEventSource = TwoKeyEventSource(ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonesRegistry).getContractProxyAddress("TwoKeyEventSource"));
        ownerPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;
        conversionQuota = _conversionQuota;
        twoKeySingletonesRegistry = _twoKeySingletonesRegistry;
        erc20InvoiceToken = _erc20InvoiceToken;
        campaignName = _campaignName;
        publicMetaHash = _publicMetaHash;
        privateMetaHash = _privateMetaHash;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        minDonationAmount = _minDonationAmount;
        maxDonationAmount = _maxDonationAmount;
        campaignGoal = _campaignGoal;
    }

    /**
     * @notice Function where user can join to campaign and donate funds
     * @param signature is signature he's joining with
     * @param isAnonymous is representing if he wishes his name in the stats to be hidden
     */
    function joinAndDonate(bytes signature, bool isAnonymous) public goalValidator onlyInDonationLimit isOngoing payable {
        amountUserContributed[msg.sender] += msg.value;
    }

    /**
     * @notice Function where user has already joined and want to donate
     * @param isAnonymous is representing if he wishes his name in the stats to be hidden
     */
    function donate(bool isAnonymous) public goalValidator onlyInDonationLimit isOngoing payable {
        amountUserContributed[msg.sender] += msg.value;
    }

    /**
     * @notice Fallback function to handle input payments -> no referrer rewards in this case
     */
    function () goalValidator onlyInDonationLimit isOngoing payable {
    }

    /**
     * @notice Function to read donation
     */
    function getDonation(uint donationId) public view returns (bytes) {
        DonationEther memory donation = donationsEther[donationId];
        return abi.encodePacked(donation.donator, donation.amount, donation.donationTimestamp);
    }
}
