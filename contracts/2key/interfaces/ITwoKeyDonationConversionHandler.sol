pragma solidity ^0.4.0;

contract ITwoKeyDonationConversionHandler {
    function setTwoKeyDonationCampaign(
        address _twoKeyDonationCampaign,
        bool _isKYCRequired,
        uint _maxReferralRewardPercent
    ) public;

    function createDonation(address _converter, uint _donationAmount) public;
}
