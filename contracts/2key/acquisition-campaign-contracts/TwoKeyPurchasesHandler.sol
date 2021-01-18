pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/IERC20.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyPurchasesHandler is UpgradeableCampaign {

    //Safe math for math operations
    using SafeMath for *;

    //Enumerator for vesting amounts
    enum VestingAmount {BONUS, BASE_AND_BONUS}
    VestingAmount vestingAmount;

    mapping(uint => uint) public portionToUnlockingDate;


    bool initialized;
    bool isDistributionDateChanged;

    address proxyConversionHandler;
    address public assetContractERC20;
    address converter;
    address contractor;
    address twoKeyEventSource;


    uint maxConverterBonusPercent; // Maximal bonus percent per converter
    uint numberOfPurchases;
    uint bonusTokensVestingStartShiftInDaysFromDistributionDate;
    uint tokenDistributionDate; // Start of token distribution
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
        require(values[4] > 0 && values[4] <= 100);
        require(initialized == false);

        tokenDistributionDate = values[2];
        maxDistributionDateShiftInDays = values[3];
        numberOfDaysBetweenPortions = values[5];
        bonusTokensVestingStartShiftInDaysFromDistributionDate = values[6];
        vestingAmount = VestingAmount(values[7]);
        maxConverterBonusPercent = values[9];
        if(vestingAmount == VestingAmount.BONUS && maxConverterBonusPercent > 0) {
            numberOfVestingPortions = values[4] + 1;
        } else if (vestingAmount == VestingAmount.BONUS) {
            numberOfVestingPortions = 1;
        } else {
            numberOfVestingPortions = values[4];
        }
        contractor = _contractor;
        assetContractERC20 = _assetContractERC20;
        twoKeyEventSource = _twoKeyEventSource;
        proxyConversionHandler = _proxyConversionHandler;

        portionToUnlockingDate[0] = tokenDistributionDate;
        uint bonusVestingStartDate;
        uint i = 1;
        // In case vested amounts are both bonus and base, bonusTokensVestingStartShiftInDaysFromDistributionDate is ignored
        if(vestingAmount == VestingAmount.BASE_AND_BONUS) {
            //in thie case, bonusVestingStartDate is actually just the date of the second portion
            bonusVestingStartDate = tokenDistributionDate.add(numberOfDaysBetweenPortions.mul(1 days));
            for(i=1; i<numberOfVestingPortions; i++) {
                portionToUnlockingDate[i] = bonusVestingStartDate.add((i-1).mul(numberOfDaysBetweenPortions.mul(1 days)));
            }
        } else if(vestingAmount == VestingAmount.BONUS && maxConverterBonusPercent > 0) {
            // ONLY BONUS
            //numberOfVestingPortions == number of portions of bonus only, meaning if numberOfVestingPortions==4, will be total of base + 4 portions of bonus
            bonusVestingStartDate = tokenDistributionDate.add(bonusTokensVestingStartShiftInDaysFromDistributionDate.mul(1 days));
            for(i=1; i<numberOfVestingPortions; i++) {
                portionToUnlockingDate[i] = bonusVestingStartDate.add((i-1).mul(numberOfDaysBetweenPortions.mul(1 days)));
            }
        }
        initialized = true;
    }


    function startVesting(
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
        numberOfPurchases++;
    }


    function bonusVestingOnly(
        uint _baseTokens,
        uint _bonusTokens,
        uint _conversionId,
        address _converter
    )
    internal
    {
        uint [] memory portionAmounts = new uint[](numberOfVestingPortions);
        bool [] memory isPortionWithdrawn = new bool[](numberOfVestingPortions);
        portionAmounts[0] = _baseTokens;

        uint bonusPortionAmount = 0;
        if(numberOfVestingPortions > 1) {
            bonusPortionAmount = _bonusTokens.div(numberOfVestingPortions.sub(1));
        }

        for(uint i=1; i<numberOfVestingPortions; i++) {
            portionAmounts[i] = bonusPortionAmount;
        }

        Purchase memory purchase = Purchase(
            _converter,
            _baseTokens,
            _bonusTokens,
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
        uint [] memory portionAmounts = new uint[](numberOfVestingPortions);
        bool [] memory isPortionWithdrawn = new bool[](numberOfVestingPortions);

        uint totalAmount = _baseTokens.add(_bonusTokens);
        uint portion = totalAmount.div(numberOfVestingPortions);

        for(uint i=0; i<numberOfVestingPortions; i++) {
            portionAmounts[i] = portion;
        }

        Purchase memory purchase = Purchase(
            _converter,
            _baseTokens,
            _bonusTokens,
            portionAmounts,
            isPortionWithdrawn
        );

        conversionIdToPurchase[_conversionId] = purchase;
    }


    function changeDistributionDate(
        uint _newDate
    )
    public
    {
        require(msg.sender == contractor);
        require(isDistributionDateChanged == false);
        require(_newDate.sub(maxDistributionDateShiftInDays.mul(1 days)) <= tokenDistributionDate);
        require(now < tokenDistributionDate);

        uint shift = _newDate.sub(tokenDistributionDate);

        // If the date is changed shifting all tokens unlocking dates for the difference
        for(uint i=0; i<numberOfVestingPortions;i++) {
            portionToUnlockingDate[i] = portionToUnlockingDate[i].add(shift);
        }

        isDistributionDateChanged = true;
        tokenDistributionDate = _newDate;
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
        require(p.isPortionWithdrawn[portion] == false && block.timestamp > portionToUnlockingDate[portion]);

        ITwoKeyEventSource(twoKeyEventSource).tokensWithdrawnFromPurchasesHandler(
            ITwoKeyConversionHandler(proxyConversionHandler).getMainCampaignContractAddress(),
            conversionId,
            p.portionAmounts[portion]
        );

        p.isPortionWithdrawn[portion] = true;
        //Transfer tokens
        require(IERC20(assetContractERC20).transfer(p.converter, p.portionAmounts[portion]));
    }


    function getPurchaseInformation(
        uint _conversionId
    )
    public
    view
    returns (address, uint, uint, uint[], bool[], uint[])
    {
        Purchase memory p = conversionIdToPurchase[_conversionId];
        uint [] memory unlockingDates = getPortionsUnlockingDates();
        return (
            p.converter,
            p.baseTokens,
            p.bonusTokens,
            p.portionAmounts,
            p.isPortionWithdrawn,
            unlockingDates
        );
    }


    function getAvailableAndLockedAndWithdrawnTokensPerConversion(
        uint _conversionId
    )
    public
    view
    returns (uint,uint,uint)
    {
        Purchase memory p = conversionIdToPurchase[_conversionId];
        uint[] memory unlockingDates = getPortionsUnlockingDates();

        uint availableTokens = 0;
        uint lockedTokens = 0;
        uint withdrawnTokens = 0;

        /**
         If unlocking date is after block.timestamp, then this portion amount and all after it are locked
         Otherwise, if the date is before block.timestamp, it's either withdrawn or available to withdraw
         */

        // This logic will be performed only if the conversion is executed
        // Added to avoid revert
        if(p.converter != address(0)) {
            for(uint j=0; j<unlockingDates.length; j++) {
                if(block.timestamp < unlockingDates[j]) {
                    lockedTokens = lockedTokens.add(p.portionAmounts[j]);
                } else {
                    if(p.isPortionWithdrawn[j] == true) {
                        withdrawnTokens = withdrawnTokens.add(p.portionAmounts[j]);
                    } else {
                        availableTokens = availableTokens.add(p.portionAmounts[j]);
                    }
                }
            }
        }


        return (availableTokens, lockedTokens, withdrawnTokens);
    }


    function getStaticInfo()
    public
    view
    returns (uint,uint,uint,uint,uint,uint)
    {
        return (
            bonusTokensVestingStartShiftInDaysFromDistributionDate,
            tokenDistributionDate,
            numberOfVestingPortions,
            numberOfDaysBetweenPortions,
            maxDistributionDateShiftInDays,
            uint(vestingAmount)
        );
    }


    function getPortionsUnlockingDates()
    public
    view
    returns (uint[])
    {
        uint portions = numberOfVestingPortions;

        uint [] memory dates = new uint[](portions);
        for(uint i=0; i< portions; i++) {
            dates[i] = portionToUnlockingDate[i];
        }
        return dates;
    }


    function getMetricsPerConverterPerCampaign(
        address _converter
    )
    public
    view
    returns (uint, uint,uint,uint)
    {
        uint totalUnitsConverterBought;
        (,,totalUnitsConverterBought) = ITwoKeyConversionHandler(proxyConversionHandler).getConverterPurchasesStats(_converter);

        uint[] memory conversionIds = ITwoKeyConversionHandler(proxyConversionHandler).getConverterConversionIds(_converter);
        uint totalAvailable;
        uint totalLocked;
        uint totalWithdrawn;

        for(uint i=0; i<conversionIds.length; i++) {
            uint available;
            uint locked;
            uint withdrawn;

            (available,locked,withdrawn) = getAvailableAndLockedAndWithdrawnTokensPerConversion(conversionIds[i]);

            totalAvailable = totalAvailable.add(available);
            totalLocked = totalLocked.add(locked);
            totalWithdrawn = totalWithdrawn.add(withdrawn);
        }

        return (totalUnitsConverterBought, totalAvailable, totalLocked, totalWithdrawn);
    }

}
