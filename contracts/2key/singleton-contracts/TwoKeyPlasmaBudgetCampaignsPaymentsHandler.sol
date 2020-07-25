pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage.sol";

import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyPlasmaCampaign.sol";

contract TwoKeyPlasmaBudgetCampaignsPaymentsHandler is Upgradeable {

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    // Mapping if distribution cycle is submitted
    string constant _distributionCyclePaymentSubmitted = "distributionCyclePaymentSubmitted";

    // Mapping how much referrer received in distribution cycle
    string constant _referrer2CycleId2TotalDistributedInCycle = "referrer2CycleId2TotalDistributedInCycle";

    // Mapping referrer to all campaigns he participated at
    string constant _referrer2campaignAddresses = "referrer2campaignAddresses";

    // Mapping referrer to how much rebalanced amount he has pending
    string constant _referrer2rebalancedPending = "referrer2rebalancedPending";

    ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice          Modifier which will be used to restrict calls to only maintainers
     */
    modifier onlyMaintainer {
        require(
            ITwoKeyMaintainersRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry"))
            .checkIsAddressMaintainer(msg.sender) == true
        );
        _;
    }

    /**
     * @notice          Modifier restricting access to the function only to campaigns
     *                  created using TwoKeyPlasmaFactory contract
     */
    modifier onlyBudgetCampaigns {
        require(
            ITwoKeyPlasmaFactory(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaFactory"))
            .isCampaignCreatedThroughFactory(msg.sender)
        );
        _;
    }


    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * ------------------------------------------------
     *        Internal getters and setters
     * ------------------------------------------------
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

    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }

    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key,value);
    }


    function getAddressArray(
        bytes32 key
    )
    internal
    view
    returns (address [])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }



    function pushAddressToArray(
        bytes32 key,
        address value
    )
    internal
    {
        address[] memory currentArray = PROXY_STORAGE_CONTRACT.getAddressArray(key);

        uint newLength = currentArray.length + 1;

        address [] memory newArray = new address[](newLength);

        uint i;

        for(i=0; i<newLength - 1; i++) {
            newArray[i] = currentArray[i];
        }

        // Append the last value there.
        newArray[i] = value;

        // Store this array
        PROXY_STORAGE_CONTRACT.setAddressArray(key, newArray);
    }

    /**
     * @notice          Function to delete address array for specific influencer
     */
    function deleteAddressArray(
        bytes32 key
    )
    internal
    {
        address [] memory emptyArray = new address[](0);
        PROXY_STORAGE_CONTRACT.setAddressArray(key, emptyArray);
    }

    /**
     * @notice          Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }


    /**
     * ------------------------------------------------------------------------------------------------
     *              EXTERNAL FUNCTION CALLS - MAINTAINER ACTIONS CAMPAIGN ENDING FUNNEL
     * ------------------------------------------------------------------------------------------------
     */

    /**
     * @notice          Function where maintainer will submit N calls and store campaign
     *                  inside array of campaigns for influencers that it's not distributed but ended
     *
     *                  END CAMPAIGN OPERATION ON PLASMA CHAIN
     * @param           campaignPlasma is the plasma address of campaign
     * @param           start is the start index
     * @param           end is the ending index
     */
    function markCampaignAsDoneAndAssignToActiveInfluencers(
        address campaignPlasma,
        uint start,
        uint end
    )
    public
    onlyMaintainer
    {
        address[] memory influencers = ITwoKeyPlasmaCampaign(campaignPlasma).getActiveInfluencers(start,end);

        uint i;
        uint len = influencers.length;

        for(i=0; i<len; i++) {
            bytes32 key = keccak256(
                _referrer2campaignAddresses,
                influencers[i]
            );
            pushAddressToArray(key, campaignPlasma);
        }
    }


    /**
     * @notice          At the point when we want to do the payment
     */
    function rebalanceInfluencerRatesAndPrepareForRewardsDistribution(
        address [] referrers,
        uint currentRate2KEY
    )
    public
    onlyMaintainer
    {
        uint numberOfReferrers = referrers.length;
        uint i;
        uint j;
        for(i=0; i<numberOfReferrers; i++) {
            // Load current referrer
            address referrer = referrers[i];
            // Get all the campaigns of specific referrer
            address[] memory referrerCampaigns = getCampaignsReferrerHasPendingBalances(referrer);
            // Get number of pending campaigns for this referrer
            uint numberOfCampaigns = referrerCampaigns.length;
            // Calculate how much is total payout for this referrer
            uint referrerTotalPayoutAmount = 0;
            // Iterate through campaigns
            for(j = 0; j < referrerCampaigns.length; j++) {
                // Load campaign address
                address campaignAddress = referrerCampaigns[j];
                // Update on plasma campaign contract rebalancing ratio at this moment
                referrerTotalPayoutAmount =
                referrerTotalPayoutAmount + ITwoKeyPlasmaCampaign(campaignAddress).computeAndSetRebalancingRatioForReferrer(
                    referrer,
                    currentRate2KEY
                );
            }
            // Delete referrer campaigns which are pending rewards
            deleteReferrerPendingCampaigns(
                keccak256(_referrer2campaignAddresses, referrer)
            );

            // Store referrer total payout amount
            setReferrerToRebalancedAmountPending(referrer, referrerTotalPayoutAmount);
        }
    }


    /**
     * ------------------------------------------------
     *        Public getters
     * ------------------------------------------------
     */

    /**
     * @notice          Function to check if distribution cycle was submitted
     *
     * @param           cycleId is the ID of cycle which is distributed
     */
    function getIfDistributionCyclePaymentsSubmitted(
        uint cycleId
    )
    public
    view
    returns (bool)
    {
        bytes32 key = keccak256(
            _distributionCyclePaymentSubmitted,
            cycleId
        );

        return getBool(key);
    }

    /**
     * @notice          Function to get campaign where referrer is having pending
     *                  balance. If empty array, means all rewards are already being
     *                  distributed.
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    public
    view
    returns (address[]) {

        bytes32 key = keccak256(
            _referrer2campaignAddresses,
            referrer
        );

        return getAddressArray(key);
    }

    function deleteReferrerPendingCampaigns(
        bytes32 key
    )
    internal
    {
        deleteAddressArray(key);
    }

    function getRebalancedPendingAmountForReferrer(
        address referrer
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_referrer2rebalancedPending, referrer));
    }

    function setReferrerToRebalancedAmountPending(
        address referrer,
        uint amount
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_referrer2rebalancedPending, referrer),
            amount
        );
    }
}
