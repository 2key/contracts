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
        uint amountOfTokens
    )
    public
    {
        if(getCampaignContractor(campaignPlasma) == address(0)) {
            setCampaignContractor(campaignPlasma, msg.sender);
        }
        // Require msg.sender is contractor
        require(msg.sender == getCampaignContractor());

        // Take tokens from contractor
        IERC20(token).transferFrom(msg.sender, address(this), amountOfTokens);

        // 90% of added goes to campaign budget, 10% moderator fee
        uint campaignBudget = amountOfTokens.mul(90).div(100);

        // Compute leftover for moderator
        uint moderatorLeftover = amountOfTokens.sub(campaignBudget);

        // Increase campaign budget for this campaign
        increaseCampaignBudget(campaignPlasma,campaignBudget);

    }


    function addSubscription2KEY(address campaignPlasma, uint amountOfTokens) public;
    function addSubscriptionStableCoin(address campaignPlasma, address token, uint amountOfTokens) public;
    function getLatestSubscriptionStartAndEndDate(address campaignPlasma) public view returns (uint,uint);



    /**
     * @notice          Function to increase budget for campaign
     * @param           campaignPlasma is the plasma address of campaign
     * @param           amountOfTokens is the amount of tokens user is adding to the budget
     */
    function increaseCampaignBudget(
        address campaignPlasma,
        uint amountOfTokens
    )
    internal
    {
        uint totalAdded = getTotalAddedBudgetForCampaign(campaignPlasma);

        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_campaignPlasma2TotalBudgetAdded, campaignPlasma),
            totalAdded.add(amountOfTokens)
        );
    }

    /**
     * @notice          Function to get total budget added for the campaign
     * @param           campaignPlasma is the plasma address of campaign
     * @return          total budget added for campaign in WEI
     */
    function getTotalAddedBudgetForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2TotalBudgetAdded, campaignPlasma));
    }

    /**
     * @notice          Function to get campaign contractor address
     * @param           campaignPlasma is the address of plasma campaign deployed to sidechain
     * @return          campaign contractor address
     */
    function getCampaignContractor(
        address campaignPlasma
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor,campaignPlasma));
    }

    /**
     * @notice          Function to set campaign contractor address
     * @param           campaignPlasma is the address of campaign deployed to sidechain
     * @param           contractor is contractor address
     */
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
