pragma solidity ^0.4.24;

contract ITwoKeyAcquisitionCampaignERC20 {
    function getSymbol() public view returns (string);
    function getAssetContractAddress() public view returns (address);
    function updateRefchainRewards(uint256 _maxReferralRewardETHWei, address _converter) public;
}
