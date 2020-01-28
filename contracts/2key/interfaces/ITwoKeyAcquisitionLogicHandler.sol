pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract ITwoKeyAcquisitionLogicHandler {
    function canContractorWithdrawUnsoldTokens() public view returns (bool);
    bool public IS_CAMPAIGN_ACTIVE;
    function getEstimatedTokenAmount(uint conversionAmountETHWei, bool isFiatConversion) public view returns (uint, uint);
    function getReferrers(address customer) public view returns (address[]);
    function updateRefchainRewards(address _converter, uint _conversionId, uint totalBounty2keys) public;
    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint);
    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, bool isFiatConversion, uint debtPaid) external returns (bool,uint);
}
