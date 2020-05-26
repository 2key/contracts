pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyBookkeeperStorage.sol";
import "../libraries/SafeMath.sol";

/**
 * @author Nikola Madjarevic @madjarevicn
 * Contract which is going to serve as an accountant for all incomes to 2KEY
 */
contract TwoKeyBookkeeper is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    string constant _earningsPerCampaignAsModerator = "earningsPerCampaignAsModerator";
    string constant _totalEarningsAsModerator = "totalEarningsAsModerator";
    string constant _totalWithdrawnFromAdminAsModeratorEarnings = "totalWithdrawnFromAdminAsModeratorEarnings";

    string constant _totalFeesCollectedFromKyber = "totalFeesCollectedFromKyber";
//    string constant _totalCollectedFromKyberFees = "feesWithdrawnFromKyber";
    string constant _totalWithdrawnKyberFeesFromAdmin = "totalWithdrawnKyberFeesFromAdmin";

    string constant _feesCollectedInFeeManagerInCurrency = "feesCollectedFromFeeManagerInCurrency";
    string constant _totalWithdrawnFromFeeManagerToAdminInCurrency = "totalWithdrawnFromFeeManagerToAdminInCurrency";
    string constant _totalWithdrawnFeeManagerFeesFromAdminInCurrency = "totalWithdrawnFromAdminInCurrency";

    //TODO: Add upgradable exchange DAI released

    bool initialized;

    ITwoKeyBookkeeperStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function to set initial parameters in this contract
     * @param _twoKeySingletoneRegistry is the address of TwoKeySingletoneRegistry contract
     * @param _proxyStorage is the address of proxy of storage contract
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBookkeeperStorage(_proxyStorage);

        //TODO: Add a function to migrate current state in 2KEY admin earnings at the moment of creation for moderator fees
        initialized = true;
    }

    /**
     * @notice          Function to handle state whenever there's an income to moderator from
     *                  2KEY campaigns
     * @param           campaignAddress is the address of campaign from which are earnings being taken
     * @param           incomeAmount is the amount in 2KEY tokens
     */
    function addModeratorIncome(
        address campaignAddress,
        uint incomeAmount
    )
    public
    {
        bytes32 keyHashForModeratorEarningsPerCampaign = keccak256(_earningsPerCampaignAsModerator, campaignAddress);
        bytes32 keyHashForCurrentTotalModeratorIncome = keccak256(keccak256(_totalEarningsAsModerator));

        uint moderatorEarningsPerCampaign = PROXY_STORAGE_CONTRACT.getUint(keyHashForModeratorEarningsPerCampaign);
        uint moderatorTotalIncome = PROXY_STORAGE_CONTRACT.getUint(keyHashForCurrentTotalModeratorIncome);

        PROXY_STORAGE_CONTRACT.setUint(keyHashForModeratorEarningsPerCampaign, moderatorEarningsPerCampaign.add(incomeAmount));
        PROXY_STORAGE_CONTRACT.setUint(keyHashForCurrentTotalModeratorIncome, moderatorTotalIncome.add(incomeAmount));
    }

    /**
     * @notice          Function to add fees earned from Kyber DEX when we withdraw them
     *
     * @param           amountIn2KEY is the amount of 2KEY tokens collected as fees
     */
    function addFeesCollectedFromKyber(
        uint amountIn2KEY
    )
    public
    {
        bytes32 keyHashForAmountCollectedFromKyber = keccak256(_totalFeesCollectedFromKyber);

        uint collectedFromKyberByNow = PROXY_STORAGE_CONTRACT.getUint(keyHashForAmountCollectedFromKyber);

        PROXY_STORAGE_CONTRACT.setUint(keyHashForAmountCollectedFromKyber, collectedFromKyberByNow.add(amountIn2KEY));
    }


    /**
     * @notice          Function to add fees earned from Fee Manager in specific currency
     *
     * @param           currency is the currency in which we have taken fees, currently it can
     *                  be 2KEY, ETH, or DAI
     * @param           amount is the amount collected in specific currency
     */
    function addFeesCollectedFromFeeManager(
        string currency,
        uint amount
    )
    public
    {
        bytes32 keyHashForAmountOfFeesCollectedInCurrency = keccak256(_feesCollectedFromFeeManagerInCurrency, currency);

        uint collectedFeesInCurrency = PROXY_STORAGE_CONTRACT.getUint(keyHashForAmountOfFeesCollectedInCurrency);

        PROXY_STORAGE_CONTRACT.setUint(keyHashForAmountOfFeesCollectedInCurrency, collectedFeesInCurrency.add(amount));
    }

    /**
     * @notice          Function to account whenever there's withdraw from TwoKeyAdmin performed
     *
     * @param           beneficiary is the address which received this amount of money
     * @param           amount is the amount in 2KEY tokens which are being withdrawn
     */
    function updateModeratorFeesWithdrawnFromAdmin(
        address beneficiary,
        uint amount
    )
    public
    {
        bytes32 keyHashForModeratorFeesWithdrawnFromAdmin = keccak256(_totalWithdrawnFromAdminAsModeratorEarnings);

        uint withdrawnByNowFromAdmin = PROXY_STORAGE_CONTRACT.getUint(keyHashForModeratorFeesWithdrawnFromAdmin);

        PROXY_STORAGE_CONTRACT.setUint(keyHashForModeratorFeesWithdrawnFromAdmin, withdrawnByNowFromAdmin.add(amount));
    }

    /**
     * @notice          Function to account whenever there's withdraw from TwoKeyAdmin performed
     *
     * @param           beneficiary is the address which received this amount of money
     * @param           amount is the amount in 2KEY tokens which are being withdrawn
     */
    function updateFeesFromKyberWithdrawnFromAdmin(
        address beneficiary,
        uint amount
    )
    public
    {

    }



}
