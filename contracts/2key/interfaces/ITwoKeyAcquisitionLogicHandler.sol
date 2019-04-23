pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract ITwoKeyAcquisitionLogicHandler {
    function requirementIsOnActive() public view returns (bool);
    function canMakeFiatConversion(address converter, uint amountWillingToSpendFiatWei) public view returns (bool,uint);
    function canMakeETHConversion(address converter, uint amountWillingToSpendEthWei) public view returns (bool,uint);
    function getEstimatedTokenAmount(uint conversionAmountETHWei, bool isFiatConversion) public view returns (uint, uint);

    function setTwoKeyAcquisitionCampaignContract(
        address _acquisitionCampaignAddress,
        address twoKeySingletoneRegistry,
        address _twoKeyConversionHandler) public;

    function getReferrers(address customer, address acquisitionCampaignContract) public view returns (address[]);
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter, uint _conversionId, uint totalBounty2keys) public;
    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint);
}
