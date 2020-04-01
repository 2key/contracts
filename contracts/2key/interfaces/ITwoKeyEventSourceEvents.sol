pragma solidity ^0.4.24;
/**
 * @author Nikola Madjarevic
 * Created at 2/13/19
 */
contract ITwoKeyEventSourceEvents {
    // This 2 functions will be always in the interface since we need them very often
    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);

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

    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external;

    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external;


    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public;


}
