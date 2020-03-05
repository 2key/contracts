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
        address _twoKeyEconomy
    )
    public
    {
        // Requirement for campaign initialization
        require(isCampaignInitialized == false);

        // Set the contractor of the campaign
        contractor = _contractor;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));

        twoKeyEconomy = _twoKeyEconomy;

        // Set the moderator of the campaign
        moderator = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Set target url to be visited
        targetUrl = _url;

        // Set bounty per conversion
        bountyPerConversion = _bountyPerConversion;

        //Set mirror campaign on plasma
        mirrorCampaignOnPlasma = _mirrorCampaignOnPlasma;

        isCampaignInitialized = true;
    }

}
