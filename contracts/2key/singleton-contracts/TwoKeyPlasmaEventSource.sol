pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaEventSourceStorage.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";


/**
 * @title Contract which is used to emit events on sidechain
 * @author Nikola Madjarevic (Github : @madjarevicn)
 */
contract TwoKeyPlasmaEventSource is Upgradeable {


    // Determinator if campaign is initialized
    bool initialized;


    // Pointer to storage contract
    ITwoKeyPlasmaEventSourceStorage public PROXY_STORAGE_CONTRACT;
    // Address of plasma singleton registry contract
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    /**
     * Constants
     */
    string constant _twoKeyPlasmaRegistry = "TwoKeyPlasmaRegistry";
    string constant _twoKeyPlasmaFactory = "TwoKeyPlasmaFactory";



    /**
     * @notice          Function which is replication for constructor
     *                  and can be called only once in a lifetime
     *
     * @param           _twoKeyPlasmaSingletonRegistry is the address of plasma singleton registry
     * @param           _proxyStorage is the proxy address of storage contract
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaEventSourceStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice          Event emitted when assigning plasma to ethereum address
     */
    event Plasma2Ethereum(
        address plasma,
        address eth
    );


    /**
     * @notice          Event emitted when assigning plasma to handle
     */
    event Plasma2Handle(
        address plasma,
        string handle
    );


    /**
     * @notice          Event emitted when conversion on budget campaigns is created
     */
    event ConversionCreated(
        address campaignAddressPlasma,
        address campaignAddressPublic,
        uint conversionID,
        address contractor,
        address converter
    );


    /**
     * @notice          Event emitted when conversion on budget campaigns is executed
     */
    event ConversionExecuted(
        address campaignAddressPlasma,
        uint conversionID
    );


    /**
     * @notice          Event emitted when conversion on budget campaigns is rejected
     */
    event ConversionRejected(
        address campaignAddressPlasma,
        uint conversionID,
        uint statusCode
    );


    /**
     * @notice          Event emitted when CPC campaign is created
     */
    event CPCCampaignCreated(
        address proxyCPCCampaignPlasma,
        address contractorPlasma
    );


    /**
     * @notice          Modifier restricting calls only to TwoKeyPlasmaFactory contract
     */
    modifier onlyTwoKeyPlasmaFactory {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(msg.sender == twoKeyPlasmaFactory);
        _;
    }


    /**
     * @notice          Modifier restricting calls only to whitelisted campaigns
     */
    modifier onlyWhitelistedCampaigns {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(ITwoKeyPlasmaFactory(twoKeyPlasmaFactory).isCampaignCreatedThroughFactory(msg.sender) == true);
        _;
    }

    /**
     * @notice          Modifier restricting calls only to TwoKeyPlasmaRegistry contract
     */
    modifier onlyTwoKeyPlasmaRegistry {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaRegistry);
        require(msg.sender == twoKeyPlasmaRegistry);
        _;
    }


    /**
     * @notice          Function to return proxy address of the contract registered
     *                  in TwoKeyPlasmaSingletonRegistry contract
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }


    /**
     * @notice          Function that emits an event when conversion is created
     *
     * @param           campaignAddressPublic is the public address of the campaign
     * @param           conversionID is the ID of the conversion
     * @param           contractor is the contractor plasma address
     * @param           converter is the converter plasma address
     *
     * @dev             Can be only called by whitelisted campaigns
     */
    function emitConversionCreatedEvent(
        address campaignAddressPublic,
        uint conversionID,
        address contractor,
        address converter
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionCreated(
            msg.sender,
            campaignAddressPublic,
            conversionID,
            contractor,
            converter
        );
    }


    /**
     * @notice          Function to emit event when conversion is executed
     *
     * @param           conversionID is the ID of the conversion being executed
     */
    function emitConversionExecutedEvent(
    uint conversionID
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionExecuted(
            msg.sender,
            conversionID
        );
    }


    /**
     * @notice          Function to emit event when conversion is rejected
     *
     * @param           conversionID is the ID of the conversion being rejected
     * @param           statusCode is the code which is mapping to reason of rejection
     */
    function emitConversionRejectedEvent(
        uint conversionID,
        uint statusCode
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionRejected(
            msg.sender,
            conversionID,
            statusCode
        );
    }


    /**
     * @notice          Function to emit an event when CPC campaign is being created
     *
     * @param           proxyCPCCampaignPlasma is the proxy address for CPC campaign on plasma network
     * @param           contractorPlasma is contractor plasma address
     */
    function emitCPCCampaignCreatedEvent(
        address proxyCPCCampaignPlasma,
        address contractorPlasma
    )
    public
    onlyTwoKeyPlasmaFactory
    {
        emit CPCCampaignCreated(
            proxyCPCCampaignPlasma,
            contractorPlasma
        );
    }


    /**
     * @notice          Function to emit event when plasma is linked to ethereum address
     *
     * @param           _plasma is the plasma address which is being linked
     * @param           _ethereum is the ethereum address which is being linked
     */
    function emitPlasma2EthereumEvent(
        address _plasma,
        address _ethereum
    )
    public
    onlyTwoKeyPlasmaRegistry
    {

        emit Plasma2Ethereum(_plasma, _ethereum);
    }



    /**
     * @notice          Function to emit event when plasma is linked to user handle
     *
     * @param           _plasma is the plasma address which is being linked
     * @param           _handle is the users handle to which we're linking plasma
     */
    function emitPlasma2HandleEvent(
        address _plasma,
        string _handle
    )
    public
    onlyTwoKeyPlasmaRegistry
    {
        emit Plasma2Handle(_plasma, _handle);
    }

}
