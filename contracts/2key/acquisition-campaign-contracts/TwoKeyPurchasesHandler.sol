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
    mapping(uint => address) conversionIdToConverter;

    event TokensWithdrawn(
        uint timestamp,
        address methodCaller,
        address tokensReceiver,
        uint portionId,
        uint portionAmount
    );

    struct Purchase {
        address converter;
        uint baseTokens;
        uint bonusTokens;
        uint [] unlockingDates;
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

        bonusTokensVestingStartShiftInDaysFromDistributionDate = values[2];
        tokenDistributionDate = values[3];
        numberOfVestingPortions = values[4];
        numberOfDaysBetweenPortions = values[5];
        maxDistributionDateShiftInDays = values[6];
        vestingAmount = VestingAmount(values[7]);
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
        require(msg.sender == proxyConversionHandler);
        if(vestingAmount == VestingAmount.BASE_AND_BONUS) {
            baseAndBonusVesting(_baseTokens, _bonusTokens, _conversionId);
        } else {
            bonusVestingOnly(_baseTokens, _bonusTokens, _conversionId);
        }
        conversionIdToConverter[_conversionId] = _converter;
    }

    function bonusVestingOnly(uint _baseTokens, uint _bonusTokens, uint _conversionId) internal {
        conversionIdToPortionToUnlockingDate[_conversionId][0] = tokenDistributionDate;
        conversionIdToPortionToUnlockingDate[_conversionId][1] = tokenDistributionDate + bonusTokensVestingStartShiftInDaysFromDistributionDate*(1 days);
        for(uint i=2; i<numberOfVestingPortions; i++) {
            conversionIdToPortionToUnlockingDate[_conversionId][1] + (i-1) * (numberOfDaysBetweenPortions * (1 days));
        }
    }

    function baseAndBonusVesting(uint _baseTokens, uint _bonusTokens, uint _conversionId) internal {
        uint totalAmount = _baseTokens + _bonusTokens;
        uint portion = totalAmount / numberOfVestingPortions;
        conversionIdToPortionToUnlockingDate[_conversionId][0] = tokenDistributionDate;
        for(uint i=1; i<numberOfVestingPortions; i++) {
            conversionIdToPortionToUnlockingDate[_conversionId][i] = tokenDistributionDate + i * (numberOfDaysBetweenPortions * (1 days));
        }
    }


}
