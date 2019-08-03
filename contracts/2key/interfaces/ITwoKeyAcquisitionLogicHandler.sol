pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract ITwoKeyAcquisitionLogicHandler {
    function canContractorWithdrawUnsoldTokens() public view returns (bool);
    function canContractorWithdrawFunds() public view returns (bool);
    bool public IS_CAMPAIGN_ACTIVE;
    function getEstimatedTokenAmount(uint conversionAmountETHWei, bool isFiatConversion) public view returns (uint, uint);
    function getReferrers(address customer, address acquisitionCampaignContract) public view returns (address[]);
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter, uint _conversionId, uint totalBounty2keys) public;
    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint);
    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, bool isFiatConversion) external returns (bool);
}
