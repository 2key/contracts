pragma solidity ^0.4.0;

import "../Upgradeable.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/IERC20.sol";


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

    mapping(uint => Purchase) conversionIdToPurchase;

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
        uint [] portionAmounts;
        bool [] isPortionWithdrawn;
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
    )
    public
    {
        require(msg.sender == proxyConversionHandler);
        if(vestingAmount == VestingAmount.BASE_AND_BONUS) {
            baseAndBonusVesting(_baseTokens, _bonusTokens, _conversionId, _converter);
        } else {
            bonusVestingOnly(_baseTokens, _bonusTokens, _conversionId, _converter);
        }
    }

    function bonusVestingOnly(
        uint _baseTokens,
        uint _bonusTokens,
        uint _conversionId,
        address _converter
    )
    internal
    {
        uint [] memory unlockingDates = new uint[](numberOfVestingPortions+1);
        uint [] memory portionAmounts = new uint[](numberOfVestingPortions+1);
        bool [] memory isPortionWithdrawn = new bool[](numberOfVestingPortions+1);
        unlockingDates[0] = tokenDistributionDate;
        portionAmounts[0] = _baseTokens;

        uint bonusVestingStartDate = tokenDistributionDate + bonusTokensVestingStartShiftInDaysFromDistributionDate * (1 days);
        uint bonusPortionAmount = _bonusTokens / numberOfVestingPortions;

        for(uint i=1; i<numberOfVestingPortions + 1; i++) {
            unlockingDates[i] = bonusVestingStartDate + (i-1) * (numberOfDaysBetweenPortions * (1 days));
            portionAmounts[i] = bonusPortionAmount;
        }

        Purchase memory purchase = Purchase(
            _converter,
            _baseTokens,
            _bonusTokens,
            unlockingDates,
            portionAmounts,
            isPortionWithdrawn
        );

        conversionIdToPurchase[_conversionId] = purchase;
    }

    function baseAndBonusVesting(
        uint _baseTokens,
        uint _bonusTokens,
        uint _conversionId,
        address _converter
    )
    internal
    {
        uint [] memory unlockingDates = new uint[](numberOfVestingPortions);
        uint [] memory portionAmounts = new uint[](numberOfVestingPortions);
        bool [] memory isPortionWithdrawn = new bool[](numberOfVestingPortions);

        uint totalAmount = _baseTokens + _bonusTokens;
        uint portion = totalAmount / numberOfVestingPortions;

        for(uint i=0; i<numberOfVestingPortions; i++) {
            unlockingDates[i] = tokenDistributionDate + i * numberOfDaysBetweenPortions * (1 days);
            portionAmounts[i] = portion;
        }

        Purchase memory purchase = Purchase(
            _converter,
            _baseTokens,
            _bonusTokens,
            unlockingDates,
            portionAmounts,
            isPortionWithdrawn
        );

        conversionIdToPurchase[_conversionId] = purchase;
    }


    function withdrawTokens(
        uint conversionId,
        uint portion
    )
    public
    {
        Purchase p = conversionIdToPurchase[conversionId];
        //Only converter of maintainer can call this function
        require(msg.sender == p.converter || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender) == true);
        require(p.isPortionWithdrawn[portion] == false && block.timestamp > p.unlockingDates[portion]);

        require(IERC20(assetContractERC20).transfer(p.converter, p.portionAmounts[portion]));
        p.isPortionWithdrawn[portion] = true;

        emit TokensWithdrawn (
            block.timestamp,
            msg.sender,
            converter,
            portion,
            p.portionAmounts[portion]
        );
    }

    function getStaticInfo()
    public
    view
    returns (uint,uint,uint,uint,uint,uint) {
        return (
            bonusTokensVestingStartShiftInDaysFromDistributionDate,
            tokenDistributionDate,
            numberOfVestingPortions,
            numberOfDaysBetweenPortions,
            maxDistributionDateShiftInDays,
            uint(vestingAmount)
        );
    }


}
