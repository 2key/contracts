pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/13/19
 */
contract ITwoKeyEventSourceEvents {
    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external;

    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external;

    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external;

    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external;

    function priceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    )
    external;



}
