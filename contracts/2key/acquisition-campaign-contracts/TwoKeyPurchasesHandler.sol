pragma solidity ^0.4.0;

import "../Upgradeable.sol";

contract TwoKeyPurchasesHandler is Upgradeable{

    enum VestingAmount {BONUS, BASE_AND_BONUS}
    VestingAmount vestingAmount;

    bool initialized;

    address proxyConversionHandler;
    address assetContractERC20;
    address converter;
    address contractor;
    address twoKeyEventSource;

    uint bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint tokenDistributionDate;
    uint numberOfVestingPortions; // For example 6
    uint numberOfDaysBetweenPortions; // For example 30 days
    uint maxDistributionDateShiftInDays;

    mapping(uint => mapping(uint => uint)) conversionIdToPortionToUnlockingDate;
    mapping(uint => mapping(uint => bool)) conversionIdToPortionToIsWithdrawn;

    struct Purchases {
        address converter;
        uint baseTokens;
        uint bonusTokens;
    }

    function setInitialParamsPurchasesHandler(
        uint[] values,
        address _contractor,
        address _assetContractERC20,
        address _twoKeyEventSource,
        address _proxyConversionHandler
    )
    public
    {
        require(initialized == false);

        bonusTokensVestingStartShiftInDaysFromDistributionDate = values[1];
        tokenDistributionDate = values[2];
        numberOfVestingPortions = values[3];
        numberOfDaysBetweenPortions = values[4];
        maxDistributionDateShiftInDays = values[5];

        contractor = _contractor;
        assetContractERC20 = _assetContractERC20;
        twoKeyEventSource = _twoKeyEventSource;
        proxyConversionHandler = _proxyConversionHandler;

        initialized = true;
    }


    function createPurchase(
        uint _baseTokens,
        uint _bonusTokens,
        uint _conversionId,
        address _converter
    ) public {

    }
}
