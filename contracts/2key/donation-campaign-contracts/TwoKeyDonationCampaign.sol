pragma solidity ^0.4.24;

import "./TwoKeyDonationCampaignType.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignARC.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is TwoKeyDonationCampaignType, TwoKeyCampaignARC {

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

    address erc20InvoiceToken;
    uint balanceOfEtherAndERC20;
    uint maxReferralRewardPercent;

    mapping(address => uint) amountUserContributed;

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


    function () payable {
        require(balance + msg.value <= campaignGoal);
        require(now >= campaignStartTime && now <= campaignEndTime);
    }



}
