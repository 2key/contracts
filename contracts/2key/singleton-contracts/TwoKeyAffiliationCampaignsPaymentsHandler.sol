pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyAffiliationCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITether.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyEventSource.sol";

import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

contract TwoKeyAffiliationCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";
    string constant _campaignPlasma2TotalBudgetAdded = "campaignPlasma2TotalBudgetAdded";
    string constant _campaignPlasma2TokenAddress = "campaignPlasma2TokenAddress";
    string constant _campaignPlasma2SubscriptionEnding = "campaignPlasma2SubscriptionDate";
    string constant _campaignPlasma2SubscriptionAmount2KEYs = "campaignPlasma2SubscriptionAmount2KEY";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";
    string constant _campaignPlasma2NumberOfSubscriptions = "campaignPlasma2NumberOfSubscriptions";
    string constant _total2KEYTokensEarnedFromSubscriptions = "total2KEYTokensEarnedFromSubscriptions";
    string constant _isSignatureExisting = "isSignatureExisting";


    ITwoKeyAffiliationCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;


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
     * @notice          Function to calculate new subscription ending date
     *                  and set it
     * @param           campaignPlasma is address of campaign on plasma network
     */
    function extendSubscriptionInternal(
        address campaignPlasma
    )
    internal
    {
        uint subscriptionEnding = getSubscriptionEndDate(campaignPlasma);

        if(subscriptionEnding == 0) {
            subscriptionEnding = block.timestamp;
        }

        // Extend subscription for 30 days
        uint newEndDate = subscriptionEnding + 30 * (1 days);

        // Set new subscription ending date
        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_campaignPlasma2SubscriptionEnding, campaignPlasma),
            newEndDate
        );

        // Emit event that subscription extended
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitAffiliationSubscriptionExtended(
            campaignPlasma,
            newEndDate
        );
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
        // Check if the user is contractor, once contractor set, can't be changeds
        if(getCampaignContractor(campaignPlasma) == address(0)) {
            setCampaignContractor(campaignPlasma, msg.sender);
        }

        // Check because user is not allowed to change the token address
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


    /**
     * @notice          Function to add subscription in 2KEY tokens
     * @param           campaignPlasma is the address of campaign
     * @param           amountOfTokens is the amount of tokens spent for adding subscription
     */
    function addSubscription2KEY(
        address campaignPlasma,
        uint amountOfTokens
    )
    external
    {
        require(msg.sender == getCampaignContractor(campaignPlasma));

        // Current 2KEY sell rate
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // Compute amount in USD worth of subscription
        uint amountInUSDWei = amountOfTokens.mul(rate).div(10**18);

        // Require that amount user sent is corresponding at least 99$ (100$ is subscription)
        require(amountInUSDWei >= 99 * 10**18);

        extendSubscriptionInternal(campaignPlasma);

        // Take 2KEY tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOfTokens
        );

        // Update collected tokens from subscriptions in 2KEY admin
        ITwoKeyAdmin(getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin"))
            .updateReceivedTokensFromCampaignSubscriptions(amountOfTokens);

    }


    /**
     * @notice          Function to add subscription in Stable coins
     * @param           campaignPlasma is the address of campaign
     * @param           amountOfTokens is the amount of tokens spent for adding subscription
     */
    function addSubscriptionStableCoin(
        address campaignPlasma,
        address tokenAddress,
        uint amountOfTokens
    )
    external
    {
        require(msg.sender == getCampaignContractor(campaignPlasma));

        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");

        // Compute how much USD is this amount in tokens worth
        uint amountInUSDWei = IUpgradableExchange(twoKeyUpgradableExchange).computeAmountInUsd(
            amountOfTokens,
            tokenAddress
        );

        // Require that amount user sent is corresponding at least 99$ (100$ is subscription)
        require(amountInUSDWei >= 99 * 10**18);

        // Extend subscription
        extendSubscriptionInternal(campaignPlasma);

        // Handle case for Tether due to different ERC20 interface it has
        if (tokenAddress == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDT")) {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            ITether(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfTokens
            );
        } else {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfTokens
            );
        }

        // Update upgradable exchange on received tokens
        IUpgradableExchange(twoKeyUpgradableExchange).addStableCoinsAvailableToFillReserve(amountOfTokens, tokenAddress);

        // Emit event that subscription extended
    }


    /**
     * @notice          Function to withdraw tokens earned with signature
     * @param           signature is signature produced by signatory address
     * @param           campaignAddresses is array of campaign addresses from which user is withdrawing
     * @param           rewardsPending is array of rewards per campaign user is doing withdraw
     */
    function withdrawTokensWithSignature(
        bytes signature,
        address [] campaignAddresses,
        uint [] rewardsPending
    )
    public
    {
        // Same signature can't be used twice
        require(getIfSignatureIsExisting(signature) == false);

        // Fetch who signed the message
        address messageSigner = recoverSignature(
            signature,
            msg.sender,
            campaignAddresses,
            rewardsPending
        );

        // Require that message signer is signatory address
        require(messageSigner == getSignatoryAddress());

        uint i;

        for(i = 0; i < campaignAddresses.length; i++) {
            // Get address of rewards token
            address rewardsTokenAddress = getTokenUsedForRewardingCampaign(campaignAddresses[i]);
            // Transfer earnings for this campaign
            IERC20(rewardsTokenAddress).transfer(msg.sender, rewardsPending[i]);
        }

        // Mark that sig is used.
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isSignatureExisting, signature), true);
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
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(
            keccak256(_campaignPlasma2TokenAddress, campaignPlasma)
        );
    }


    /**
     * @notice          Function to get signatory address from TwoKeyAdmin contract
     */
    function getSignatoryAddress()
    internal
    view
    returns (address)
    {
        return ITwoKeyAdmin(getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin")).getSignatoryAddress();
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


    /**
     * @notice          Function to get if signature is existing
     * @param           signature is the signature we're checking if exists
     */
    function getIfSignatureIsExisting(
        bytes signature
    )
    public
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(keccak256(_isSignatureExisting, signature));
    }


    /**
     * @notice          Function to recover the signature
     * @param           signature is the signature of user
     * @param           referrerPublic is referrer public address
     * @param           campaigns is the array of campaigns for signed rewards
     * @param           rewards is array of rewards in campaigns correspondingly
     */
    function recoverSignature(
        bytes signature,
        address referrerPublic,
        address [] campaigns,
        uint [] rewards
    )
    public
    pure
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(referrerPublic)),
                keccak256(abi.encodePacked(campaigns,rewards))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }
}
