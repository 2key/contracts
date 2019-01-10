pragma solidity ^0.4.24;

contract ITwoKeyConversionHandler {
    function supportForCreateConversion(
        address _contractor,
        uint256 _contractorProceeds,
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        uint256 _moderatorFeeETHWei,
        uint256 baseTokensForConverterUnits,
        uint256 bonusTokensForConverterUnits,
        uint256 expiryConversion) external;

    function setAnonymous(address _contractor, bool _isAnonymous) external;
    function cancelAndRejectContract() external;
    function setTwoKeyAcquisitionCampaignERC20(address _twoKeyAcquisitionCampaignERC20, address _moderator, address _contractor, address _assetContractERC20, address upgradableExchange) external;
    function getModeratorBalanceAndTotalEarnings() external view returns (uint,uint);

}
