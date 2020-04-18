pragma solidity ^0.4.24;

import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "./TwoKeyBudgetCampaign.sol";

/**
 * @author Nikola Madjarevic
 * @author Ehud Ben-Reuven
 * Date added : 1st December 2019
 */
contract TwoKeyCPCCampaign is UpgradeableCampaign, TwoKeyBudgetCampaign {

    //The url being shared for the campaign
    string public targetUrl;



    //Replacement for constructor
    function setInitialParamsCPCCampaign(
        address _contractor,
        address _twoKeySingletonRegistry,
        string _url,
        address _mirrorCampaignOnPlasma,
        uint _bountyPerConversion,
        string _campaignCurrency,
        address _twoKeyEconomy
    )
    public
    {
        // Set that campaign is initialized and unable calling this function anymore
        initializeCampaign();

        // Set the contractor of the campaign
        contractor = _contractor;

        // Set address of TWO_KEY_SINGLETON_REGISTRY
        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        // Set address of twoKeyEventSource
        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));

        // Set address of twoKeyEconomy
        twoKeyEconomy = _twoKeyEconomy;

        // Set the moderator of the campaign
        moderator = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Set target url to be visited
        targetUrl = _url;

        // Set bounty per conversion
        bountyPerConversion = _bountyPerConversion;

        // Set mirror campaign on plasma
        mirrorCampaignOnPlasma = _mirrorCampaignOnPlasma;

        // Set the currency for the campaign
        campaignCurrency = _campaignCurrency;

    }

}
