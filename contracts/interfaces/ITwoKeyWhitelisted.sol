pragma solidity ^0.4.24;

contract ITwoKeyWhitelisted {
    function setTwoKeyAcquisitionCampaignERC20(address _twoKeyAcquisitionCampaignERC20, address _moderator, address _contractor) public;
    function supportForCanceledEscrow(address _converterAddress) public returns (uint256);
    function supportForCancelAssetTwoKey(address _converterAddress) public view;
    function supportForExpireEscrow(address _converterAddress) public view;
    function supportForCreateConversion(
        address _contractor,
        uint256 _contractorProceeds,
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        uint256 _moderatorFeeETHWei,
        uint256 baseTokensForConverterUnits,
        uint256 bonusTokensForConverterUnits,
        uint256 expiryConversion) public;
}
