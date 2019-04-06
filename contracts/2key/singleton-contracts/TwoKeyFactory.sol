pragma solidity ^0.4.0;

import "../Upgradeable.sol";
import "../MaintainingPattern.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../UpgradabilityProxyAcquisition.sol";

/**
 * @author Nikola Madjarevic
 * @title Contract used to deploy proxies for other non-singleton contracts
 */
contract TwoKeyFactory is Upgradeable, MaintainingPattern {

    //Address of singleton registry
    ITwoKeySingletoneRegistryFetchAddress public twoKeySingletonRegistry;


    /**
     * @notice Function to set initial parameters for the contract
     * @param _twoKeySingletonRegistry is the address of singleton registry contract
     * @param _twoKeyAdmin is the address if twoKeyAdmin contract
     * @param _maintainers is the array of maintainers
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _twoKeyAdmin,
        address [] _maintainers
    )
    public
    {
        require(twoKeySingletonRegistry != address(0));

        twoKeyAdmin = _twoKeyAdmin;
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }

        twoKeySingletonRegistry = ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonRegistry);
    }

    /**
     * @notice Function used to deploy all necessary proxy contracts in order to use the campaign.
     * @dev This function will handle all necessary actions which should be done on the contract
     * in order to make them ready to work. Also, we've been unfortunately forced to use arrays
     * as arguments since the stack is not deep enough to handle this amount of input information
     * since this method handles kick-start of 3 contracts
     * @param addresses is array of addresses needed [assetContractERC20,moderator]
     * @param valuesConversion is array containing necessary values to start conversion handler contract
     * @param valuesLogicHandler is array of values necessary to start logic handler contract
     * @param values is array containing values necessary to start campaign contract
     * @param _currency is the main currency token price is set
     * @param _nonSingletonHash is the hash of non-singleton contracts active with responding
     * 2key-protocol version at the moment
     */
    function createProxiesForAcquisitions(
        address[] addresses,
        uint[] valuesConversion,
        uint[] valuesLogicHandler,
        uint[] values,
        string _currency,
        string _nonSingletonHash
    )
    public
    payable
    {
//        // Deploy proxies for all 3 contracts
//        //TODO: Versions are now hardcoded to 1.0, maybe to get dynamically always the latest version, but store the old ones
//        //Deploy proxy for Acquisition contract
//        UpgradabilityProxyAcquisition proxyAcquisition = new UpgradabilityProxyAcquisition("TwoKeyAcquisitionCampaignERC20", "1.0");
//        Upgradeable(proxyAcquisition).initialize.value(msg.value)(msg.sender);
//
//        //Deploy proxy for ConversionHandler contract
//        UpgradabilityProxyAcquisition proxyConversions = new UpgradabilityProxyAcquisition("TwoKeyConversionHandler", "1.0");
//        Upgradeable(proxyConversions).initialize.value(msg.value)(msg.sender);
//
//        //Deploy proxy for LogicHandlerContract
//        UpgradabilityProxyAcquisition proxyLogicHandler = new UpgradabilityProxyAcquisition("TwoKeyAcquisitionLogicHandler", "1.0");
//        Upgradeable(proxyLogicHandler).initialize.value(msg.value)(msg.sender);
//
//
//        // Set initial arguments inside Conversion Handler contract
//        IHandleCampaignDeployment(proxyConversions).setInitialParamsConversionHandler(
//            valuesConversion,
//            proxyAcquisition,
//            msg.sender,
//            addresses[0], //ERC20 address
//            getContractProxyAddress("TwoKeyEventSource"),
//            getContractProxyAddress("TwoKeyBaseReputationRegistry")
//        );
//
//        // Set initial arguments inside Logic Handler contract
//        IHandleCampaignDeployment(proxyLogicHandler).setInitialParamsLogicHandler(
//            valuesLogicHandler,
//            _currency,
//            addresses[0], //asset contract erc20
//            addresses[1], // moderator
//            msg.sender,
//            proxyAcquisition,
//            address(this),
//            proxyConversions
//        );
//
//        // Set initial arguments inside AcquisitionCampaign contract
//        IHandleCampaignDeployment(proxyAcquisition).setInitialParamsCampaign(
//            address(this),
//            address(proxyLogicHandler),
//            address(proxyConversions),
//            addresses[1], //moderator
//            addresses[0], //asset contract
//            msg.sender, //contractor
//            values
//        );
//
//        // Validate campaign so it will be approved to interact (and write) to/with our singleton contracts
//        ITwoKeyCampaignValidator(getContractProxyAddress("TwoKeyCampaignValidator"))
//        .validateAcquisitionCampaign(proxyAcquisition, _nonSingletonHash);
//
//        emit ProxyForCampaign(proxyLogicHandler, proxyConversions, proxyAcquisition, msg.sender, block.timestamp);
    }



}
