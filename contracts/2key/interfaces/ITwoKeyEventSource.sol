pragma solidity ^0.4.24;


contract ITwoKeyEventSource {

    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);
    function isAddressMaintainer(address _maintainer) public view returns (bool);
    function getTwoKeyDefaultIntegratorFeeFromAdmin() public view returns (uint);
    function joined(address _campaign, address _from, address _to) external;
    function rejected(address _campaign, address _converter) external;

    function convertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external;

    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint);

    function convertedDonation(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external;

    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external;

    function tokensWithdrawnFromPurchasesHandler(
        address campaignAddress,
        uint _conversionID,
        uint _tokensAmountWithdrawn
    )
    external;

    function emitDebtEvent(
        address _plasmaAddress,
        uint _amount,
        bool _isAddition,
        string _currency
    )
    external;

    function emitReceivedTokensToDeepFreezeTokenPool(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitReceivedTokensAsModerator(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitDAIReleasedAsIncome(
        address _campaignContractAddress,
        uint _amountOfDAI
    )
    public;

    function emitEndedBudgetCampaign(
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    )
    public;


    function emitUserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    )
    public;

    function emitRebalancedRewards(
        uint cycleId,
        uint difference,
        string action
    )
    public;
}
