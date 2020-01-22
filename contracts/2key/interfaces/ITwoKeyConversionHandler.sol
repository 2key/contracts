pragma solidity ^0.4.24;

contract ITwoKeyConversionHandler {

    bool public isFiatConversionAutomaticallyApproved;
    address public twoKeyPurchasesHandler;

    function supportForCreateConversion(
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        bool isConversionFiat,
        bool _isAnonymous,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;


    function getConverterConversionIds(
        address _converter
    )
    external
    view
    returns (uint[]);


    function getConverterPurchasesStats(
        address _converter
    )
    public
    view
    returns (uint,uint,uint);


    function getStateForConverter(
        address _converter
    )
    public
    view
    returns (bytes32);

    function getMainCampaignContractAddress()
    public
    view
    returns (address);

}
