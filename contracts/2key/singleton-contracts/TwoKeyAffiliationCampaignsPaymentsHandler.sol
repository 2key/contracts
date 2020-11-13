pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/storage-contracts/ITwoKeyAffiliationCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/IERC20.sol";

contract TwoKeyAffiliationCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils{

    using SafeMath for *;

    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";
    string constant _campaignPlasma2TotalBudgetAdded = "campaignPlasma2TotalBudgetAdded";
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

    function addBudgetForCampaign(
        address campaignPlasma,
        address token,
        uint amount
    )
    public
    {
        if(getCampaignContractor(campaignPlasma) == address(0)) {
            setCampaignContractor(campaignPlasma, msg.sender);
        }

        require(msg.sender == getCampaignContractor());

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // 90% of added goes to campaign budget, 10% moderator fee
        uint campaignBudget = amount.mul(90).div(100);

        // Compute leftover for moderator
        uint moderatorLeftover = amount.sub(campaignBudget);

    }


    function addMonthlySubscriptionForCampaign(address campaignPlasma, address token, uint amount) public;
    function getSubscriptionExpireDate(address campaignPlasma) public view returns (uint);



    function getCampaignContractor(
        address campaignPlasma
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor,campaignPlasma));
    }


    function setCampaignContractor(
        address campaignPlasma,
        address contractor
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(
            keccak256(_campaignPlasma2Contractor,campaignPlasma),
            contractor
        );
    }

}
