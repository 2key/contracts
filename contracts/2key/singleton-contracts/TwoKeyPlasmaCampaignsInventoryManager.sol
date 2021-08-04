pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyAdmin.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryManagerStorage.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";
import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/ITwoKeyPlasmaCampaign.sol";

import "../libraries/SafeMath.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventoryManager contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventoryManager is Upgradeable {

    using SafeMath for uint;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryManagerStorage PROXY_STORAGE_CONTRACT;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";
    string constant _twoKeyCPCCampaignPlasma = "TwoKeyCPCCampaignPlasma";

    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2LeftOverForContractor = "campaignPlasma2LeftOverForContractor";
    string constant _campaignPlasma2ReferrerRewardsTotal = "campaignPlasma2ReferrerRewardsTotal";
    string constant _campaignPlasma2ModeratorEarnings = "campaignPlasma2ModeratorEarnings";
    string constant _campaignPlasma2Budget2Key = "campaignPlasma2Budget2Key";
    string constant _campaignPlasma2BudgetUSD = "campaignPlasma2BudgetUSD";
    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2bountyPerConversionUSD = "campaignPlasma2bountyPerConversionUSD";
    string constant _campaignPlasma2Contractor = "campaignPlasma2Contractor";   // msg.sender
    string constant _campaignPlasma2LeftoverWithdrawnByContractor = "campaignPlasma2LeftoverWithdrawnByContractor";
    string constant _campaignPlasma2EarningsByModerator = "campaignPlasma2EarningsByModerator";
    string constant _distributionCycle2TotalDistributed = "distributionCycle2TotalDistributed";
    string constant _moderatorTotalEarningWithdrawn2KEY = "moderatorTotalEarningWithdrawn2KEY";
    string constant _moderatorTotalEarningWithdrawnUSD = "moderatorTotalEarningWithdrawnUSD";

    string constant _numberOfCycles = "numberOfCycles";

    // Mapping referrer to all campaigns he participated at and are having pending distribution
    string constant _referrer2pendingCampaignAddresses = "referrer2pendingCampaignAddresses";
    // Mapping moderator to all campaigns that are in pending of distribution
    string constant _moderator2pendingCampaignAddresses = "moderator2pendingCampaignAddresses";


    /**
     * @notice Function for contract initialization
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaCampaignsInventoryManagerStorage(_proxyStorage);

        initialized = true;
    }


    /**
     * @notice      Modifier which will be used to restrict set function calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }


    /**
     * @notice      Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }


    /**
     * @notice          Function that allocates specified amount of 2KEY from users balance to this contract's balance
     * @notice          Function can be called several times
     */
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversion2KEY,
        address campaignAddressPlasma
    )
    public
    {
        // Allow a user add the budget several times but in same token
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0) || 
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == msg.sender
        );

        if (PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0)) {    // Initialize the campaign
            uint rate = 10**18;
            // Set contractor user
            PROXY_STORAGE_CONTRACT.setAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma), msg.sender);
            // Set the amount of 2KEY
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma), amount);
            // Set 2Key bounty per conversion value
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignAddressPlasma), bountyPerConversion2KEY);
            // Set true value for 2Key directly budgeting
            PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma), true);

            // Perform direct 2Key transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transfer2KEYFrom(msg.sender, campaignAddressPlasma, amount);

            // Set initial parameters and validates campaign
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversion2KEY, true);

        } else {    // Add the budget
            // Update total 2Key
            uint currentAmount = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma), currentAmount.add(amount));

            // Perform direct 2Key transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transfer2KEYFrom(msg.sender, campaignAddressPlasma, amount);

            // Change CPC campaign parameters
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .addCampaignBounty(amount, true);
        }

        // Emit an event that the inventory is added in L2_2KEY
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitAddInventory2KEY(
                amount,
                bountyPerConversion2KEY,
                campaignAddressPlasma
            );
    }

    /**
     * @notice          Function that allocates specified amount of USD from users balance to this contract's balance
     * @notice          Function can be called several times
     */
    function addInventoryUSD(
        uint amount,
        uint bountyPerConversionUSD,
        address campaignAddressPlasma
    )
    public
    {
        // Allow a user add the budget several times but in same token
        require(
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0) || 
            PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == msg.sender
        );

        if (PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma)) == address(0)) {    // Initialize the campaign
            uint rate = 10**18;
            // Set contractor user
            PROXY_STORAGE_CONTRACT.setAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma), msg.sender);
            // Set amount of Stable coins
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma), amount);
            // Set current bountyPerConversionUSD
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2bountyPerConversionUSD, campaignAddressPlasma), bountyPerConversionUSD);
            // Set false value for non-2Key budgeting
            PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma), false);

            // Perform a transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transferUSDFrom(msg.sender, campaignAddressPlasma, amount);

            // Set initial parameters and validates campaign
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .setInitialParamsAndValidateCampaign(amount, rate, bountyPerConversionUSD, false);

        } else {    // Add the budget
            // Update total stable coins
            uint currentAmount = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma), currentAmount.add(amount));

            // Perform a transfer
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transferUSDFrom(msg.sender, campaignAddressPlasma, amount);
            
            // Change CPC campaign parameters
            ITwoKeyCPCCampaignPlasma(campaignAddressPlasma)
                .addCampaignBounty(amount, false);
        }

        // Emit an event that the inventory is added in L2_USD
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitAddInventoryUSD(
                amount,
                bountyPerConversionUSD,
                campaignAddressPlasma
            );
    }

    /**
     * @notice          Withdraw all the pending rewards of the referrer
     */
    function withdrawReferrerPendingRewards()
    public
    {
        address referrer = msg.sender;

        // Get all the campaigns of specific referrer
        address[] memory referrerCampaigns = getCampaignsReferrerHasPendingBalances(referrer);

        // Delete array of inProgress campaigns
        deleteAddressArray(
            keccak256(_referrer2pendingCampaignAddresses, referrer)
        );

        // Iterate through campaigns
        for(uint j = 0; j < referrerCampaigns.length; j++) {
            // Load campaign address
            address campaignAddress = referrerCampaigns[j];
            // Transfer plasma balance to referrer
            ITwoKeyPlasmaCampaign(campaignAddress).withdrawReferrerCamapignEarningsL2(referrer);
        }

    }

    /**
     * @notice          Withdraw all the pending earnings of moderator
     */
    function withdrawModeratorEarnings()
    public
    {
        uint moderatorTotalEarningWithdrawn2KEY = PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorTotalEarningWithdrawn2KEY));
        uint moderatorTotalEarningWithdrawnUSD = PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorTotalEarningWithdrawnUSD));

        uint moderatorTotalBalance2KEY;
        uint moderatorTotalBalanceUSD;

        // Get all the plasma campaigns of moderator
        address[] memory moderatorCampaignsPlasma = getCampaignsModeratorHasPendingBalances();

        // Delete array of inProgress campaigns
        deleteAddressArray(
            keccak256(_moderator2pendingCampaignAddresses)
        );

        (moderatorTotalBalance2KEY, moderatorTotalBalanceUSD) = getModeratorTotalPlasmaBalance();

        moderatorTotalEarningWithdrawn2KEY = moderatorTotalEarningWithdrawn2KEY.add(moderatorTotalBalance2KEY);
        moderatorTotalEarningWithdrawnUSD = moderatorTotalEarningWithdrawnUSD.add(moderatorTotalBalanceUSD);

        // Iterate through campaigns and initialize moderator balance
        for(uint j = 0; j < moderatorCampaignsPlasma.length; j++) {
            // Load campaign address
            address campaignPlasma = moderatorCampaignsPlasma[j];

            // Transfer plasma balance to moderator
            ITwoKeyPlasmaCampaign(campaignPlasma).withdrawModeratorCamapignEarningsL2();
        }

        PROXY_STORAGE_CONTRACT.setUint(keccak256(_moderatorTotalEarningWithdrawn2KEY), moderatorTotalEarningWithdrawn2KEY);
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_moderatorTotalEarningWithdrawnUSD), moderatorTotalEarningWithdrawnUSD);
    }

    /**
     * @notice Returns moderator balance
     * @return (uint, uint) 2KEY balance, USD balance
     */
    function getModeratorTotalPlasmaBalance()
    public
    returns (uint, uint)
    {
        uint moderatorTotalBalance2KEY;
        uint moderatorTotalBalanceUSD;

        uint moderatorBalance;

        // Get all the plasma campaigns of moderator
        address[] memory moderatorCampaignsPlasma = getCampaignsModeratorHasPendingBalances();

        // Iterate through campaigns
        for(uint j = 0; j < moderatorCampaignsPlasma.length; j++) {
            // Load campaign address
            address campaignPlasma = moderatorCampaignsPlasma[j];

            // get moderator balance
            (, moderatorBalance) = ITwoKeyPlasmaCampaign(campaignPlasma).getModeratorTotalEarningsAndBalance();

            if (PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma)) == true) {
                moderatorTotalBalance2KEY = moderatorTotalBalance2KEY.add(moderatorBalance);
            } else {
                moderatorTotalBalanceUSD = moderatorTotalBalanceUSD.add(moderatorBalance);
            }
        }

        return (moderatorTotalBalance2KEY, moderatorTotalBalanceUSD);
    }

    /**
     * @notice Returns moderator total withdrawn earnings
     * @return (uint, uint) 2KEY earnings, USD earnings
     */
    function getModeratorTotalPlasmaWithdrawn()
    public
    returns (uint, uint)
    {
        uint moderatorTotalWithdrawn2KEY;
        uint moderatorTotalWithdrawnUSD;

        moderatorTotalWithdrawn2KEY = PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorTotalEarningWithdrawn2KEY));
        moderatorTotalWithdrawnUSD = PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorTotalEarningWithdrawnUSD));

        return (moderatorTotalWithdrawn2KEY, moderatorTotalWithdrawnUSD);
    }

    /**
     * @notice          Function to end selected budget campaign by maintainer, and perform
     *                  actions regarding rebalancing, reserving tokens, and distributing
     *                  moderator earnings, as well as calculating leftover for contractor
     *
     * @param           campaignPlasma is the plasma address of the campaign
     */
    function endCampaignWithdrawContractorLeftOverAndModeratorEarningsBalance(
        address campaignPlasma
    )
    public
    onlyMaintainer
    {
        // Check if campaign has not ended yet
        require(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma)) == false);
        // Setting bool that campaign is over
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma), true);

        // Get how many tokens were inserted at the beginning
        uint initialBountyForCampaign;
        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma)) == true) {
            // if campaign was directly budgeted with 2KEY
            initialBountyForCampaign = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignPlasma));
        } else {
            // if campaign was budgeted with stable coin
            initialBountyForCampaign = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignPlasma));
        }

        (, uint totalAmountForModeratorRewards) = ITwoKeyPlasmaCampaign(campaignPlasma).getTotalReferrerRewardsAndTotalModeratorEarnings();
        uint totalAmountForReferrerRewards = ITwoKeyPlasmaCampaign(campaignPlasma).getTotalReferrerRewardsEarned();

        // Get leftover for the contractor
        uint leftoverForContractor = initialBountyForCampaign.sub(totalAmountForReferrerRewards).sub(totalAmountForModeratorRewards);
        withdrawCampaignLeftoverForContractor(campaignPlasma);

        // Set moderator earnings for this campaign and immediately distribute them
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2ModeratorEarnings, campaignPlasma), totalAmountForModeratorRewards);
        withdrawCampaignModeratorEarnings(campaignPlasma);

        // Leftover for contractor
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignPlasma), leftoverForContractor);
        // Set total amount to use for referrers
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma), totalAmountForReferrerRewards);

        // Emit an event to checksum all the balances per campaign
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitEndedBudgetCampaign(
                campaignPlasma,
                leftoverForContractor,
                totalAmountForModeratorRewards
            );
    }

    /**
     * @notice          Function to set how many tokens are being distributed to moderator
     *                  as well as distribute them.
     * @param           campaignPlasma is the plasma address of selected campaign
     */
    function withdrawCampaignModeratorEarnings(
        address campaignPlasma
    )
    internal
    {
        address twoKeyCongress = getAddressFromTwoKeySingletonRegistry("TwoKeyCongress"); 

        // Get moderatorBalance
        uint moderatorBalance = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2ModeratorEarnings, campaignPlasma));
        // Require that there is an existing amount of moderatorBalance
        require(moderatorBalance > 0);
        // Require that moderator has not already withdrawn the earnings
        require(
            PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2EarningsByModerator, campaignPlasma)) == false
        );
        // Set value that moderator did perform the withdraw
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2EarningsByModerator, campaignPlasma), true);
        // Perform transfer of moderator earnings
        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma)) == true) {
            // Transfer 2KEY tokens to moderator
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).transfer2KEYFrom(
                campaignPlasma,
                twoKeyCongress,
                moderatorBalance
            );
        } else {
            // Transfer USD tokens to moderator
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).transferUSDFrom(
                campaignPlasma,
                twoKeyCongress,
                moderatorBalance
            );
        }
    }

    /**
     * @notice          Function where contractor can withdraw if there's any leftover on his campaign
     * @param           campaignPlasmaAddress is plasma address of campaign
     */
    function withdrawCampaignLeftoverForContractor(
        address campaignPlasmaAddress
    )
    public
    {
        address contractorAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignPlasmaAddress));
        // Require that the caller is the contractor
        require(msg.sender == contractorAddress);
        // Get leftoverForContractor
        uint leftoverForContractor = PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignPlasmaAddress));
        // Require that there is an existing amount of leftoverForContractor
        require(leftoverForContractor > 0);
        // Require that contractor has not already withdrawn the leftover
        require(
            PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignPlasmaAddress)) == false
        );
        // Set value that contractor did perform the withdraw
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignPlasmaAddress), true);
        // Perform transfer of leftover to contractor
        if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasmaAddress)) == true) {
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transferUSDFrom(
                    campaignPlasmaAddress,
                    contractorAddress,
                    leftoverForContractor
                );
        } else {
            ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
                .transfer2KEYFrom(
                    campaignPlasmaAddress,
                    contractorAddress,
                    leftoverForContractor
                );
        }
    }

    function appendToArray(
        bytes32 keyBaseArray,
        bytes32 keyArrayToAppend
    )
    internal
    {
        address[] memory baseArray = PROXY_STORAGE_CONTRACT.getAddressArray(keyBaseArray);
        address[] memory arrayToAppend = PROXY_STORAGE_CONTRACT.getAddressArray(keyArrayToAppend);

        uint len = baseArray.length + arrayToAppend.length;

        address[] memory newBaseArray = new address[](len);

        uint i;
        uint j;

        // Copy base array
        for(i=0; i< baseArray.length; i++) {
            newBaseArray[i] = baseArray[i];
        }

        // Copy array to append
        for(i=baseArray.length; i<len; i++) {
            newBaseArray[i] = arrayToAppend[j];
            j++;
        }

        PROXY_STORAGE_CONTRACT.setAddressArray(keyBaseArray, newBaseArray);
    }

    function pushAddressToArray(
        bytes32 key,
        address value
    )
    public
    {
        address[] memory currentArray = PROXY_STORAGE_CONTRACT.getAddressArray(key);

        uint newLength = currentArray.length + 1;

        address [] memory newArray = new address[](newLength);

        uint i;

        for(i=0; i<newLength - 1; i++) {
            newArray[i] = currentArray[i];
        }

        // Append the last value there.
        newArray[i] = value;

        // Store this array
        PROXY_STORAGE_CONTRACT.setAddressArray(key, newArray);
    }


    /**
     * @notice          Function to get campaign where referrer is having pending
     *                  balance. If empty array, means all rewards are already being
     *                  distributed.
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    public
    view
    returns (address[])
    {
        bytes32 key = keccak256(
            _referrer2pendingCampaignAddresses,
            referrer
        );

        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

    /**
     * @notice          Function to get campaign where moderator is having pending
     *                  balance. If empty array, means all rewards are already being
     *                  distributed.
     */
    function getCampaignsModeratorHasPendingBalances()
    public
    view
    returns (address[])
    {
        bytes32 key = keccak256(
            _moderator2pendingCampaignAddresses
        );

        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

    /**
     * @notice          Returns total claimable 2KEY rewards on all curent campaigns with balance for this referrer
     * @param           referrer is the address of referrer
     * @return          (uint, address[], uint[]) total claimable 2KEY rewards, campaign array with claimable rewards, balance array of campaigns with claimable rewards
     */
    function getTotalReferrerBalanceOnL2PPCCampaigns2KEY(
        address referrer
    )
    public
    view
    returns (uint, address[] memory, uint[] memory)
    {
        // Get all pending campaigns for this referrer
        address[] memory campaigns = getCampaignsReferrerHasPendingBalances(referrer);

        uint referrerTotalPendingPayout2KEY;
        address[] campaigns2KEY;
        uint[] campaignBalanes2KEY;

        // Iterate through all campaigns
        for(uint i = 0; i < campaigns.length; i++) {
            // Add to total pending payout referrer plasma balance
            if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaigns[i])) == true) {
                campaigns2KEY.push(campaigns[i]);
                campaignBalanes2KEY.push(ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).get2KEYBalance(campaigns[i]));
                referrerTotalPendingPayout2KEY = referrerTotalPendingPayout2KEY.add(ITwoKeyPlasmaCampaign(campaigns[i]).getReferrerPlasmaBalance(referrer));
            } 
        }

        return (referrerTotalPendingPayout2KEY, campaigns2KEY, campaignBalanes2KEY);
    }

    /**
     * @notice          Returns total claimable USD rewards on all curent campaigns with balance for this referrer
     * @param           referrer is the address of referrer
     * @return          (uint, address[], uint[]) total claimable USD rewards, campaign array with claimable rewards, balance array of campaigns with claimable rewards
     */
    function getTotalReferrerBalanceOnL2PPCCampaignsUSD(
        address referrer
    )
    public
    view
    returns (uint, address[] memory, uint[] memory)
    {
        // Get all pending campaigns for this referrer
        address[] memory campaigns = getCampaignsReferrerHasPendingBalances(referrer);

        uint referrerTotalPendingPayoutUSD;
        address[] campaignsUSD;
        uint[] campaignBalanesUSD;

        // Iterate through all campaigns
        for(uint i = 0; i < campaigns.length; i++) {
            // Add to total pending payout referrer plasma balance
            if(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaigns[i])) == false) {
                campaignsUSD.push(campaigns[i]);
                campaignBalanesUSD.push(ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager)).getUSDBalance(campaigns[i]));
                referrerTotalPendingPayoutUSD = referrerTotalPendingPayoutUSD.add(ITwoKeyPlasmaCampaign(campaigns[i]).getReferrerPlasmaBalance(referrer));
            } 
        }

        return (referrerTotalPendingPayoutUSD, campaignsUSD, campaignBalanesUSD);
    }

    /**
     * @notice          Function to delete address array for specific influencer
     */
    function deleteAddressArray(
        bytes32 key
    )
    public
    {
        address [] memory emptyArray = new address[](0);
        PROXY_STORAGE_CONTRACT.setAddressArray(key, emptyArray);
    }

    /**
     * @notice      Function that returns all information about given campaign
     * @param       campaignAddressPlasma is address of the campaign
     */
    function getCampaignInformation(
        address campaignAddressPlasma
    )
    public
    view
    returns(
        address,
        uint [],
        bool []
    )
    {
            // Address types
            // Gets campaigns contractor
            address contractorAddress = PROXY_STORAGE_CONTRACT.getAddress(keccak256(_campaignPlasma2Contractor, campaignAddressPlasma));

            // Uint types
            uint [] uintValues;
            // Gets leftover for contractor
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2LeftOverForContractor, campaignAddressPlasma)));
            // Gets campaigns total budget in 2KEY
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2Budget2Key, campaignAddressPlasma)));
            // Gets campaigns total budget in USD
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2BudgetUSD, campaignAddressPlasma)));
            // Gets bounty per conversion in 2KEY
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignAddressPlasma)));
            // Gets bounty per conversion in USD
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2bountyPerConversionUSD, campaignAddressPlasma)));
            // Gets total referrer rewards
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignAddressPlasma)));
            // Gets moderator earnings
            uintValues.push(PROXY_STORAGE_CONTRACT.getUint(keccak256(_campaignPlasma2ModeratorEarnings, campaignAddressPlasma)));

            // Boolean types
            bool [] booleanValues;
            // Gets boolean value if campaign is budgeted directly with 2Key currency
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignAddressPlasma)));
            // Gets is campaign ended
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2isCampaignEnded, campaignAddressPlasma)));
            // Gets is leftover withdrawn by contractor
            booleanValues.push(PROXY_STORAGE_CONTRACT.getBool(keccak256(_campaignPlasma2LeftoverWithdrawnByContractor, campaignAddressPlasma)));
        // Returns address of the contractor and two arrays (array of uint values and array of boolean values)
        return(
            contractorAddress,
            uintValues,
            booleanValues
        );
    }
}
