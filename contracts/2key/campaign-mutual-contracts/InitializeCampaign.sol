pragma solidity ^0.4.24;

contract InitializeCampaign {

    bool isCampaignInitialized;
    /**
     * @notice          Function to assert that startCampaignWithInitialParams can be called only once
     */
    function initializeCampaign()
    internal
    {
        require(isCampaignInitialized == false);
    }
}
