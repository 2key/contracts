pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.sol";

/**
 * TwoKeyPlasmaAffiliationCampaignsPaymentsHandler contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyPlasmaAffiliationCampaignsPaymentsHandler is Upgradeable {

    using SafeMath for *;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    // Mapping referrer to all campaigns he ever had rewards in
    string constant _referrerToCampaigns = "referrerToCampaigns";
    string constant _referrerToIsCampaignAlreadyAddedToArray = "referrerToIsCampaignAlreadyAddedToArray";

    ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage(_proxyStorage);

        initialized = true;
    }

    /*
     ************************************************************************************
     *                      INTERNAL FUNCTIONS
     ************************************************************************************
     */

    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key,value);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getAddressArray(
        bytes32 key
    )
    internal
    view
    returns (address[])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

    function setAddressArray(
        bytes32 key,
        address [] addresses
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddressArray(key, addresses);
    }

    /**
     * @notice          Function to add campaign address to list of referrer campaigns
     * @param           referrer is the referrer address
     * @param           campaign is the address of campaign
     */
    function addCampaignForReferrer(
        address referrer,
        address campaign
    )
    internal
    {
        address [] memory referrerCampaigns = getCampaignsForReferrer(referrer);

        address [] memory newReferrerCampaigns = new address[](referrerCampaigns.length + 1);

        uint i;

        // Copy existing campaigns to new array
        for(i = 0; i < referrerCampaigns.length; i++) {
            newReferrerCampaigns[i] = referrerCampaigns[i];
        }

        // Add newest campaign to the end
        newReferrerCampaigns[i] = campaign;
    }

    /*
     ************************************************************************************
     *                      PUBLIC GETTERS
     ************************************************************************************
    */



    /**
     * @notice          Function to check if campaign is added to list of referrer campaigns
     * @param           campaign is the address of the campaign
     * @param           referrer is the address of referrer
     */
    function isCampaignAddedToReferrerList(
        address campaign,
        address referrer
    )
    public
    view
    returns (bool)
    {
        return getBool(
            keccak256(_referrerToIsCampaignAlreadyAddedToArray, referrer, campaign)
        );
    }

    /**
     * @notice          Function to get campaigns for referrer
     * @param           referrer is the referrer address
     */
    function getCampaignsForReferrer(
        address referrer
    )
    public
    view
    returns (address[])
    {
        return getAddressArray(keccak256(_referrerToCampaigns,referrer));
    }


    /**
     * @notice          Function to add campaign to list of referrers campaigns
     * @param           referrer is the address of referrer
     */
    function addCampaignToListOfReferrerCampaigns(
        address referrer
    )
    public
    {
        address campaign = msg.sender;
        if(!isCampaignAddedToReferrerList(referrer, campaign)) {
            // Mark that campaign is added to the list
            setBool(
                keccak256(_referrerToIsCampaignAlreadyAddedToArray, referrer, campaign),
                true
            );
            // Add this campaign to list of referrer campaigns
            addCampaignForReferrer(referrer,campaign);
        }
    }




}
