pragma solidity ^0.4.24;

import "../UpgradabilityProxyAcquisition.sol";

import '../interfaces/ITwoKeySingletonesRegistry.sol';
import "../interfaces/IHandleCampaignDeployment.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/IStructuredStorage.sol";

import "../upgradability/UpgradeabilityProxy.sol";
import "../upgradability/Upgradeable.sol";
import "./TwoKeySingletonRegistryAbstract.sol";



/**
 * @author Nikola Madjarevic
 */
contract TwoKeySingletonesRegistry is TwoKeySingletonRegistryAbstract {

    constructor()
    public
    {
        deployer = msg.sender;
        congress = "TwoKeyCongress";
        maintainersRegistry = "TwoKeyMaintainersRegistry";
    }

}
