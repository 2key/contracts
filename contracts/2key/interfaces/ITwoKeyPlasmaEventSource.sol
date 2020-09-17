pragma solidity ^0.4.24;

contract ITwoKeyPlasmaEventSource {
    function emitPlasma2EthereumEvent(address _plasma, address _ethereum) public;
    function emitPlasma2HandleEvent(address _plasma, string _handle) public;
    function emitCPCCampaignCreatedEvent(address proxyCPCCampaignPlasma, address contractorPlasma) public;
    function emitConversionCreatedEvent(address campaignAddressPublic, uint conversionID, address contractor, address converter) public;
    function emitConversionExecutedEvent(uint conversionID) public;
    function emitConversionRejectedEvent(uint conversionID, uint statusCode) public;
    function emitCPCCampaignMirrored(address proxyAddressPlasma, address proxyAddressPublic) public;
    function emitHandleChangedEvent(address _userPlasmaAddress, string _newHandle) public;
    function emitConversionPaidEvent(uint conversionID) public;
    function emitAddedPendingRewards(address campaignPlasma, address influencer, uint amountOfTokens) public;
    function emitPaidPendingRewards(address influencer, uint amountPaid, address[] campaignsPaid, uint [] earningsPerCampaign) public;
    function emitUserRewardedInParticipationMiningEpoch(uint epochId, address user, uint reward2KeyWei) public;
}
