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



    function setRebalancedReferrerEarnings(
        address referrer,
        uint balance
    )
    public
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

}
