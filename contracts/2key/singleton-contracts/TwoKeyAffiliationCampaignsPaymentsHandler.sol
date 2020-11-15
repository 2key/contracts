pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyAffiliationCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUpgradableExchange.sol";

import "../libraries/SafeMath.sol";

contract TwoKeyAffiliationCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";
    string constant _campaignPlasma2TotalBudgetAdded = "campaignPlasma2TotalBudgetAdded";
    string constant _campaignPlasma2TokenAddress = "campaignPlasma2TokenAddress";
    string constant _campaignPlasma2SubscriptionEnding = "campaignPlasma2SubscriptionDate";
    string constant _campaignPlasma2SubscriptionAmount2KEYs = "campaignPlasma2SubscriptionAmount2KEY";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";
    string constant _campaignPlasma2NumberOfSubscriptions = "campaingPlasma2NumberOfSubscriptions";
    string constant _total2KEYTokensEarnedFromSubscriptions = "total2KEYTokensEarnedFromSubscriptions";

    ITwoKeyAffiliationCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    /**
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorageContract
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyAffiliationCampaignsPaymentsHandlerStorage(_proxyStorageContract);

        initialized = true;
    }


    /**
     * @notice          Function where user can add referral budget to the campaign
     * @param           campaignPlasma is campaign plasma address
     * @param           token is the address of token used for rewards for this campaign
     * @param           amountOfTokens is amount of tokens adding to rewards budget
     */
    function addRewardsBudgetForCampaign(
        address campaignPlasma,
        address token,
        uint amountOfTokens
    )
    external
    {
        if(getCampaignContractor(campaignPlasma) == address(0)) {
            setCampaignContractor(campaignPlasma, msg.sender);
        }

        if(getTokenUsedForRewardingCampaign(campaignPlasma) == address(0)) {
            setTokenUsedForRewardingCampaign(campaignPlasma, token);
        }

        // Require same token is used always
        require(token == getTokenUsedForRewardingCampaign(campaignPlasma));

        // Require msg.sender is contractor
        require(msg.sender == getCampaignContractor(campaignPlasma));

        // Take tokens from contractor
        IERC20(token).transferFrom(msg.sender, address(this), amountOfTokens);

        // 90% of added goes to campaign budget, 10% moderator fee
        uint campaignBudget = amountOfTokens.mul(90).div(100);

        // Compute moderator earnings for the campaign
        uint moderatorEarnings = amountOfTokens.sub(campaignBudget);

        // Increase campaign budget for this campaign
        increaseCampaignBudget(campaignPlasma,campaignBudget);

        // Increase moderator earnings for this campaign
        increaseModeratorEarnings(campaignPlasma, moderatorEarnings);

        // Emit event that rewards budget is added to campaign

    }


    function addSubscription2KEY(
        address campaignPlasma,
        uint amountOfTokens
    )
    external
    {
        require(msg.sender == getCampaignContractor(campaignPlasma));
        uint subscriptionEnding = getSubscriptionEndDate(campaignPlasma);

        if(subscriptionEnding == 0) {
            subscriptionEnding = block.timestamp;
        }

        // Current 2KEY sell rate
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // Compute amount in USD worth of subscription
        uint amountInUSDWei = amountOfTokens.mul(rate).div(10**18);

        // Require that amount user sent is corresponding at least 99$ (100$ is subscription)
        require(amountInUSDWei >= 99 * 10**18);

        // Extend subscription for 30 days
        uint newEndDate = subscriptionEnding + 30 * (1 days);

        // Set new subscription ending date
        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_campaignPlasma2SubscriptionEnding, campaignPlasma),
            newEndDate
        );

        // Take 2KEY tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOfTokens
        );

        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_total2KEYTokensEarnedFromSubscriptions),
            amountOfTokens.add(getTotal2KEYTokensEarnedFromSubscriptions())
        );

        // Emit event that subscription extended
    }

    function addSubscriptionStableCoin(
        address campaignPlasma,
        address token,
        uint amountOfTokens
    )
    external
    {
        require(msg.sender == getCampaignContractor(campaignPlasma));
    }


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
     * @notice          Function to increase moderator earnings
     * @param           campaignPlasma is plasma address of campaign
     * @param           amountOfTokens is the amount of tokens used for campaign
     */
    function increaseModeratorEarnings(
        address campaignPlasma,
        uint amountOfTokens
    )
    internal
    {
        uint totalModeratorEarnings = getModeratorEarningsPerCampaign(campaignPlasma);

        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_campaignPlasma2ModeratorEarnings, campaignPlasma),
            totalModeratorEarnings.add(amountOfTokens)
        );
    }


    /**
     * @notice          Function to set campaign contractor address
     * @param           campaignPlasma is campaign plasma address
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


    /**
     * @notice          Function to set token address which is used as rewards currency
     *                  for selected campaign
     * @param           campaignPlasma is campaign plasma address
     * @param           tokenAddress is the address of token used as rewards budget
     */
    function setTokenUsedForRewardingCampaign(
        address campaignPlasma,
        address tokenAddress
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(
            keccak256(_campaignPlasma2TokenAddress, campaignPlasma),
            tokenAddress
        );
    }


    /**
     * @notice          Function to get address of token used as rewards currency in campaign
     * @param           campaignPlasma is campaign plasma address
     * @return          rewards token address
     */
    function getTokenUsedForRewardingCampaign(
        address campaignPlasma
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(
            keccak256(_campaignPlasma2TokenAddress, campaignPlasma)
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
     * @notice          Function to get moderator earnings per campaign, in campaign rewards currency
     * @param           campaignPlasma is plasma address of campaign
     * @return          moderator earnings in campaign rewards token per campaign
     */
    function getModeratorEarningsPerCampaign(
        address campaignPlasma
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(
            keccak256(_campaignPlasma2ModeratorEarnings, campaignPlasma)
        );
    }


    /**
     * @notice          Function to get ending date of monthly subscription
     * @param           campaignPlasma is plasma address of campaign
     */
    function getSubscriptionEndDate(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(
            keccak256(_campaignPlasma2SubscriptionEnding, campaignPlasma)
        );
    }


    /**
     * @notice          Function to fetch total amount of tokens earned from subscriptions
     * @return          amount of 2KEY tokens earned in WEI units
     */
    function getTotal2KEYTokensEarnedFromSubscriptions()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(
            keccak256(_total2KEYTokensEarnedFromSubscriptions)
        );
    }

}
