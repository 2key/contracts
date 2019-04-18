pragma solidity ^0.4.0;

import "../Upgradeable.sol";

contract TwoKeyPurchasesHandler is Upgradeable{

    enum VestingAmount {BONUS, BASE_AND_BONUS}
    VestingAmount vestingAmount;

    bool initialized;

    address assetContractERC20;
    address converter;
    address contractor;
    address twoKeyEventSource;

    uint32 bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint32 tokenDistributionDate;
    uint32 numberOfVestingPortions; // For example 6
    uint32 numberOfDaysBetweenPortions; // For example 30 days
    uint32 maxDistributionDateShiftInDays;

    mapping(uint => mapping(uint => uint)) conversionIdToPortionToUnlockingDate;
    mapping(uint => mapping(uint => bool)) conversionIdToPortionToIsWithdrawn;

    struct Purchases {
        address converter;
        uint baseTokens;
        uint bonusTokens;
    }

    function setInitialParamsPurchasesHandler(
        uint32[] values,
//        uint32 _bonusTokensVestingStartShiftInDaysFromDistributionDate,
//        uint32 _tokenDistributionDate,
//        uint32 _numberOfVestingPortions,
//        uint32 _numberOfDaysBetweenPortions,
//        uint32 _maxDistributionDateShiftInDays,
        address _contractor,
        address _assetContractERC20,
        address _twoKeyEventSource
    )
    public
    {
        require(initialized == false);
        bonusTokensVestingStartShiftInDaysFromDistributionDate = values[0];
        tokenDistributionDate = values[1];
        numberOfVestingPortions = values[2];
        numberOfDaysBetweenPortions = values[3];
        maxDistributionDateShiftInDays = values[4];

        contractor = _contractor;
        assetContractERC20 = _assetContractERC20;
        twoKeyEventSource = _twoKeyEventSource;

        initialized = true;
    }
}
