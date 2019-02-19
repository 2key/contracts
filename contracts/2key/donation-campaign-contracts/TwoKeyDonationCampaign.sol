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
    bool mustReachGoal; // If not, all the funds are returned to the senders

    address erc20InvoiceToken; // ERC20 token which will be issued as an invoice
    uint maxReferralRewardPercent;

    uint balance;

    mapping(address => uint) amountUserContributed;

    mapping(address => uint[]) donatorToHisDonationsInEther;
    mapping(address => uint[]) donatorToHisDonationsInERC20;

    uint numberOfDonationsEther;
    uint numberOfDonationsERC20;

    DonationEther[] donationsEther;
    DonationERC20[] donationsERC20;

    struct DonationEther {
        address donator;
        uint amount;
        uint donationTimestamp;
    }

    struct DonationERC20 {
        address donator;
        address erc20Contract;
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
        bool _mustReachGoal,
        uint _conversionQuota,
        address _twoKeySingletoneRegistry
    ) TwoKeyCampaignARC(
        _conversionQuota, _twoKeySingletoneRegistry, _moderator
    ) public {
        erc20InvoiceToken = _erc20InvoiceToken;
        campaignName = _campaignName;
        publicMetaHash = _publicMetaHash;
        privateMetaHash = _privateMetaHash;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        minDonationAmount = _minDonationAmount;
        maxDonationAmount = _maxDonationAmount;
        campaignGoal = _campaignGoal;
        mustReachGoal = _mustReachGoal;
    }

    modifier isGoalReached {
        require(campaignGoal < balance);
        _;
    }

    function joinAndDonateERC20(bytes signature, bool isAnonymous, address erc20Contract, uint amount) public {

    }

    function donateERC20(bool isAnonymous, address erc20Contract, uint amount) public {

    }

    function joinAndDonate(bytes signature, bool isAnonymous) public payable {
        amountUserContributed[msg.sender] += msg.value;
    }

    function donate(bool isAnonymous) public payable {
        amountUserContributed[msg.sender] += msg.value;
    }


    function () payable {
        require(balance + msg.value <= campaignGoal);
        require(now >= campaignStartTime && now <= campaignEndTime);
    }

    function getEtherDonation(uint donationId) public view returns (bytes) {
        DonationEther memory donation = donationsEther[donationId];
        return abi.encodePacked(donation.donator, donation.amount, donation.donationTimestamp);
    }

    function getERC20Donation(uint donationId) public view returns (bytes) {
        DonationERC20 memory donation = donationsERC20[donationId];
        return abi.encodePacked(donation.donator, donation.erc20Contract, donation.amount, donation.donationTimestamp);
    }

    function getDonationIdsPerUser(address user) public view returns (uint[], uint[]) {
        return (donatorToHisDonationsInERC20[user], donatorToHisDonationsInEther[user]);
    }



}
