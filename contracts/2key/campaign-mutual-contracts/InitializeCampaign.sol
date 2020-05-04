pragma solidity ^0.4.24;

contract InitializeCampaign {

    bool isCampaignInitialized;
    /**
     * @notice          Function to assert that startCampaignWithInitialParams can be called only once
     */
    function initializeCampaign()
    internal
    {
        // Require that this method is not called
        require(isCampaignInitialized == false);

        // Initialize campaign
        isCampaignInitialized = true;
    }
}
