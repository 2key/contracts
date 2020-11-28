pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.sol";

/**
 * TwoKeyPlasmaAffiliationCampaignsPaymentsHandler contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyPlasmaAffiliationCampaignsPaymentsHandler is Upgradeable {

    using SafeMath for *;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;


    string constant _referrerToCampaignsWithRewards = "referrerToCampaignsWithRewards";

    ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage PROXY_STORAGE_CONTRACT;

    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage(_proxyStorage);

        initialized = true;
    }

}
