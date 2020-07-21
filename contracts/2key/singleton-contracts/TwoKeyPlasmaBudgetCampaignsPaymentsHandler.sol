pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage.sol";

import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";

contract TwoKeyPlasmaBudgetCampaignsPaymentsHandler is Upgradeable {

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _campaignPlasma2Referrer2rebalancedEarnings = "campaignPlasma2Referrer2rebalancedEarnings";
    string constant _distributionCyclePaymentSubmitted = "distributionCyclePaymentSubmitted";

    string constant _referrer2CycleId2TotalDistributedInCycle = "referrer2CycleId2TotalDistributedInCycle";
    string constant _referrer2TotalEarnings = "referrer2TotalEarnings";
    string constant _referrer2TotalEarningsPaid = "referrer2TotalEarningsPaid";
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

    function setReferrerTotalEarningsPaid(
        address referrer,
        uint amount
    )
    internal
    {
        bytes32 keyTotalDistributed = keccak256(
            _referrer2TotalEarningsPaid,
            referrer
        );

        // Increment currently total distributed for the amount distributed in this iteration
        setUint(
            keyTotalDistributed,
            getUint(keyTotalDistributed) + amount
        );
    }

    function setReferrerEarningsPerDistributionCycle(
        uint cycleId,
        address referrer,
        uint amount
    )
    internal
    {
        bytes32 key = keccak256(
            _referrer2CycleId2TotalDistributedInCycle,
            cycleId,
            referrer
        );

        setUint(key, amount);
    }

    function setDistributionPaymentCycleSubmitted(
        uint cycleId
    )
    internal
    {
        bytes32 key = keccak256(
            _distributionCyclePaymentSubmitted,
            cycleId
        );

        setBool(key, true);
    }

    /**
     * ------------------------------------------------
     *        External function calls
     * ------------------------------------------------
     */

    function setRebalancedReferrerEarnings(
        address referrer,
        uint balance
    )
    external
    onlyBudgetCampaigns
    {
        address campaignPlasma = msg.sender;

        // Generate the key for referrer total earnings from this campaign
        bytes32 keyTotalPerCampaign = keccak256(
            _campaignPlasma2Referrer2rebalancedEarnings,
            campaignPlasma,
            referrer
        );

        // Require that referrer didn't receive any rewards from this camapign in the past
        // Acting as a safeguard agains maintainer double calls
        require(getUint(keyTotalPerCampaign) == 0);

        // Set referrer total earnings per campaign
        setUint(
            keyTotalPerCampaign,
            balance
        );

        // Generate the key for referrer total earnings
        bytes32 keyTotalEarnings = keccak256(
            _referrer2TotalEarnings, referrer
        );

        // Add additional amount to referrer total earnings
        setUint(
            keyTotalEarnings,
            getUint(keyTotalEarnings) + balance
        );
    }



    /**
     * ------------------------------------------------
     *        Maintainer function calls
     * ------------------------------------------------
     */


    function updateReferrersBalancesAfterDistribution(
        uint cycleId,
        address [] referrers,
        uint [] balances
    )
    public
    onlyMaintainer
    {
        // Safeguard against submitting multiple times same results for distribution cycle
        require(getIfDistributionCyclePaymentsSubmitted(cycleId) == false);

        // Set that this distribution cycle is submitted
        setDistributionPaymentCycleSubmitted(cycleId);

        // Take the array length
        uint length = referrers.length;
        uint i;
        // Iterate through all referrers
        for(i = 0; i < length; i++) {
            // Update how much referrer received in this distribution cycle
            setReferrerEarningsPerDistributionCycle(
                cycleId,
                referrers[i],
                balances[i]
            );

            // Increase total earnings paid to referrer by the balance being paid in this cycle
            setReferrerTotalEarningsPaid(
                referrers[i],
                balances[i]
            );
        }
    }


    /**
     * ------------------------------------------------
     *        Public getters
     * ------------------------------------------------
     */

    /**
     * @notice          Function to get referrer pending balance to be distributed
     *
     * @param           referrer is the plasma address of referrer
     */
    function getReferrerPendingBalance(
        address referrer
    )
    public
    view
    returns (uint)
    {
        bytes32 keyTotalEarnings = keccak256(
            _referrer2TotalEarnings,
            referrer
        );

        bytes32 keyTotalDistributed = keccak256(
            _referrer2TotalEarningsPaid,
            referrer
        );

        return (getUint(keyTotalEarnings) - getUint(keyTotalDistributed));
    }


    /**
     * @notice          Function to return amount referrer have received in selected
     *                  distribution cycle (id)
     *
     * @param           referrer is the referrer plasma address
     * @param           cycleId is the id of distribution cycle
     */
    function getAmountReferrerReceivedInCycle(
        address referrer,
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        bytes32 key = keccak256(
            _referrer2CycleId2TotalDistributedInCycle,
            cycleId,
            referrer
        );

        return getUint(key);
    }

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

}
