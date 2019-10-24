pragma solidity ^0.4.24;

contract ITwoKeyDonationConversionHandler {
    function supportForCreateConversion(
        address _converterAddress,
        uint _conversionAmount,
        uint _maxReferralRewardETHWei,
        bool _isKYCRequired,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;

    function getAmountConverterSpent(
        address converter
    )
    public
    view
    returns (uint);

    function getAmountOfDonationTokensConverterReceived(
        address converter
    )
    public
    view
    returns (uint);

    function getStateForConverter(
        address _converter
    )
    external
    view
    returns (bytes32);

    function setExpiryConversionInHours(
        uint _expiryConversionInHours
    )
    public;

}
