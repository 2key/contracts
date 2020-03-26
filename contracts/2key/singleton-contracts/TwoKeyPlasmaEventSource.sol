pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaEventSourceStorage.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
contract TwoKeyPlasmaEventSource is Upgradeable {

    ITwoKeyPlasmaEventSourceStorage public PROXY_STORAGE_CONTRACT;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    bool initialized;
    string constant _twoKeyPlasmaRegistry = "TwoKeyPlasmaRegistry";
    string constant _twoKeyPlasmaFactory = "TwoKeyPlasmaFactory";


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


    event Plasma2Ethereum(
        address plasma,
        address eth
    );



    event Plasma2Handle(
        address plasma,
        string handle
    );


    event ConversionCreated(
        address campaignAddressPlasma,
        address campaignAddressPublic,
        uint conversionID,
        address contractor,
        address converter
    );



    event ConversionExecuted(
        address campaignAddressPlasma,
        uint conversionID
    );


    event ConversionRejected(
        address campaignAddressPlasma,
        uint conversionID,
        uint statusCode
    );


    event CPCCampaignCreated(
        address proxyCPCCampaignPlasma,
        address contractorPlasma
    );



    modifier onlyTwoKeyPlasmaFactory {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(msg.sender == twoKeyPlasmaFactory);
        _;
    }


    modifier onlyWhitelistedCampaigns {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(ITwoKeyPlasmaFactory(twoKeyPlasmaFactory).isCampaignCreatedThroughFactory(msg.sender) == true);
        _;
    }


    modifier onlyTwoKeyPlasmaRegistry {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaRegistry);
        require(msg.sender == twoKeyPlasmaRegistry);
        _;
    }


    // Internal function to fetch address from TwoKeyPlasmaSingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }



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



    function emitPlasma2EthereumEvent(
        address _plasma,
        address _ethereum
    )
    public
    onlyTwoKeyPlasmaRegistry
    {

        emit Plasma2Ethereum(_plasma, _ethereum);
    }



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
