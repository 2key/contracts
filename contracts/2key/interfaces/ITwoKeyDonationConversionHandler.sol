pragma solidity ^0.4.0;

contract ITwoKeyDonationConversionHandler {
    function supportForCreateConversion(
        address _converterAddress,
        uint _conversionAmount,
        uint _maxReferralRewardETHWei,
        bool _isAnonymous,
        bool _isKYCRequired
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;
}
