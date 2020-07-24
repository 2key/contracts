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

    string constant _campaignPlasma2Referrer2rebalancedEarnings = "campaignPlasma2Referrer2rebalancedEarnings";
    string constant _distributionCyclePaymentSubmitted = "distributionCyclePaymentSubmitted";
    string constant _referrer2CycleId2TotalDistributedInCycle = "referrer2CycleId2TotalDistributedInCycle";

    // Mapping initial rate at which inventory was bought to campaign address
    string constant _campaignPlasma2InitialRate = "campaignPlasma2InitialRate";
    // Mapping referrer to all campaigns he participated at
    string constant _referrer2campaignAddresses = "referrer2campaignAddresses";
    // Mapping referrer to campaigns to pending balances there
    string constant _referrer2campaignPlasma2PendingBalance = "referrer2campaignPlasma2PendingBalance";
    // Mapping referrer to total rebalanced earnings per campaign
    string constant _referrer2campaignPlasma2totalEarningsRebalanced = "referrer2campaignPlasma2totalEarnings";
    // Mapping referrer to his total earnings ever
    string constant _referrer2TotalEarnings = "referrer2TotalEarnings";
    // Mapping referrer to total earnings paid
    string constant _referrer2TotalEarningsPaid = "referrer2TotalEarningsPaid";
    // Mapping referrer to total earnings pending
    string constant _referrer2TotalEarningsPending = "referrer2TotalEarningsPending";


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
     * ------------------------------------------------
     *        External function calls
     * ------------------------------------------------
     */


    /**
     * @notice          Function where maintainer will submit N calls and store campaign
     *                  inside array of campaigns for influencers that it's not distributed but ended
     *
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

    function getCampaignsReferrerParticipatedIn(
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

}
