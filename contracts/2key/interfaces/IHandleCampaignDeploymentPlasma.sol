pragma solidity ^0.4.24;

contract IHandleCampaignDeploymentPlasma {

    function setInitialParamsCPCCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        string _url,
        uint [] numberValues
    )
    public;

    function setInitialParamsCPCCampaignPlasmaNoRewards(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        string _url,
        uint [] numberValues
    )
    public;
}
