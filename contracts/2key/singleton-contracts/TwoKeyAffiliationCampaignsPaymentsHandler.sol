pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyAffiliationCampaignsPaymentsHandlerStorage.sol";

contract TwoKeyAffiliationCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils{

    using SafeMath for *;

    string constant _campaignPlasma2InitialBudget = "campaignPlasma2InitialBudget";
    string constant _campaignPlasma2TokenAddress = "campaignPlasma2TokenAddress";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";
    string constant _campaignPlasma2SubscriptionTimestamp = "campaignPlasma2SubscriptionDate";
    string constant _campaignPlasma2SubscriptionAmount2KEY = "campaignPlasma2SubscriptionAmount2KEY";


    /**
     * We need:
     - campaign creation -->
     - --> add budget
     - --> and pay membership
     */
    ITwoKeyAffiliationCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorageContract
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyAffiliationCampaignsPaymentsHandlerStorage(_proxyStorageContract);

        initialized = true;
    }

    function addBudgetForCampaign(address campaignPlasma, address token, uint amount) public;
    function addMonthlySubscriptionForCampaign(address campaignPlasma, address token, uint amount) public;
    function getSubscriptionExpireDate(address campaignPlasma) public;

}
