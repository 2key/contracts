pragma solidity ^0.4.24;

contract ITwoKeyAdmin {
    function getDefaultIntegratorFeePercent() public view returns (uint);
    function getDefaultNetworkTaxPercent() public view returns (uint);
    function getTwoKeyRewardsReleaseDate() external view returns(uint);
    function updateReceivedTokensAsModerator(uint amountOfTokens) public;
    function updateReceivedTokensAsModeratorPPC(uint amountOfTokens, address campaignPlasma) public;
    function addFeesCollectedInCurrency(string currency, uint amount) public payable;

    function updateTokensReceivedFromDistributionFees(uint amountOfTokens) public;
}

