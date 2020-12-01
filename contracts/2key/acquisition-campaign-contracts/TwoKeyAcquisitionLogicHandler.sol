pragma solidity ^0.4.24;
import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignLogicHandler.sol";

/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract TwoKeyAcquisitionLogicHandler is UpgradeableCampaign, TwoKeyCampaignLogicHandler {

    bool public IS_CAMPAIGN_ACTIVE;

    address assetContractERC20;

    bool isFixedInvestmentAmount; // This means that minimal contribution is equal maximal contribution
    bool isAcceptingFiat;

    uint pricePerUnitInETHWeiOrUSD; // There's single price for the unit ERC20 (Should be in WEI)
    uint unit_decimals; // ERC20 selling data
    uint maxConverterBonusPercent; // Maximal bonus percent per converter
    uint campaignHardCapWei; // Hard cap of campaign
    uint campaignSoftCapWei; //Soft cap of campaign

    function setInitialParamsLogicHandler(
        uint [] values,
        string _currency,
        address _assetContractERC20,
        address _moderator,
        address _contractor,
        address _acquisitionCampaignAddress,
        address _twoKeySingletoneRegistry,
        address _twoKeyConversionHandler
    )
    public
    {
        require(values[1] >= values[0]);
        require(values[4] > values[3]);
        require(values[5] <= 100*(10**18));

        require(initialized == false);

        if(values[0] == values[1]) {
            isFixedInvestmentAmount = true;
        }

        minContributionAmountWei = values[0];
        maxContributionAmountWei = values[1];
        pricePerUnitInETHWeiOrUSD = values[2];
        campaignStartTime = values[3];
        campaignEndTime = values[4];
        maxConverterBonusPercent = values[5];

        //Add as 6th argument incentive model uint
        incentiveModel = IncentiveModel(values[6]);

        if(values[7] == 1) {
            isAcceptingFiat = true;
        }

        campaignHardCapWei = values[8];

        if(values[9] == 1) {
            endCampaignOnceGoalReached = true;
        }

        campaignSoftCapWei = values[10];

        currency = _currency;

        if(keccak256(_currency) == keccak256("ETH")) {
            // 0.01 ether
            require(values[0] >= (10**16));
        } else {
            // 1 dollar
            require(values[0] >= (10**18));
        }

        assetContractERC20 = _assetContractERC20;
        moderator = _moderator;
        contractor = _contractor;
        unit_decimals = IERC20(_assetContractERC20).decimals();

        twoKeyCampaign = _acquisitionCampaignAddress;
        twoKeySingletonRegistry = _twoKeySingletoneRegistry;
        twoKeyRegistry = getAddressFromRegistry("TwoKeyRegistry");

        ownerPlasma = plasmaOf(contractor);
        conversionHandler = _twoKeyConversionHandler;

        initialized = true;
    }

    /**
     * @notice Function to activate campaign, can be called only ONCE
     * @dev onlyContractor can call this function
     */
    function activateCampaign() public onlyContractor {
        require(IS_CAMPAIGN_ACTIVE == false);
        uint balanceOfTokensOnAcquisitionAtTheBeginning = IERC20(assetContractERC20).balanceOf(twoKeyCampaign);
        //balance is in weis, price is in weis and hardcap is regular number
        require((balanceOfTokensOnAcquisitionAtTheBeginning * pricePerUnitInETHWeiOrUSD).div(10**18) >= campaignHardCapWei);
        IS_CAMPAIGN_ACTIVE = true;
    }

    /**
     * @notice Function which will validate following:
     * (1) is campaign active in terms of time
     * (2) is campaign active in case contractor selected `endCampaignWhenHardCapReached`
     * (3) if converter has reached max contribution amount
     * @param converter is the address who want to convert
     * @param conversionAmount is the amount of conversion
     * @param isFiatConversion is flag if conversion is fiat or ether
     */
    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, bool isFiatConversion, uint debtPaid) external returns (bool,uint) {
        require(msg.sender == twoKeyCampaign);
        if(isAcceptingFiat) {
            require(isFiatConversion == true);
        } else {
            require(isFiatConversion == false);
        }
        require(IS_CAMPAIGN_ACTIVE == true);
        require(canConversionBeCreatedInTermsOfMinMaxContribution(converter, conversionAmount.add(debtPaid), isFiatConversion) == true);
        uint conversionAmountCampaignCurrency = convertConversionAmountToCampaignCurrency(conversionAmount, isFiatConversion);
        require(updateRaisedFundsAndValidateConversionInTermsOfHardCap(conversionAmountCampaignCurrency, isFiatConversion) == true);
        require(checkIsCampaignActiveInTermsOfTime() == true);
        return (true, conversionAmountCampaignCurrency);
    }


    function checkHowMuchUserCanConvert(uint alreadySpentETHWei, uint alreadySpentFiatWEI) internal view returns (uint) {
        if(keccak256(currency) == keccak256('ETH')) {
            uint leftToSpendInEther = maxContributionAmountWei.sub(alreadySpentETHWei);
            return leftToSpendInEther;
        } else {
            uint rate = getRateFromExchange();
            uint totalAmountSpentConvertedToFIAT = ((alreadySpentETHWei*rate).div(10**18)).add(alreadySpentFiatWEI);
            uint limit = maxContributionAmountWei; // Initially we assume it's fiat currency campaign
            uint leftToSpendInFiats = limit.sub(totalAmountSpentConvertedToFIAT);
            return leftToSpendInFiats;
        }
    }


    function convertConversionAmountToCampaignCurrency(uint conversionAmount, bool isFiatConversion) internal view returns (uint) {
        if(keccak256(currency) == keccak256('ETH') || isFiatConversion) {
            return conversionAmount;
        }
        uint rate = getRateFromExchange();
        return conversionAmount.mul(rate).div(10**18);
    }

    /**
     * @notice Function which will validate if conversion can be created if endCampaignWhenHardCapReached is selected
     * @param campaignRaisedIncludingConversion is how much will be total campaign raised with new conversion
     */
    function canConversionBeCreatedInTermsOfHardCap(uint campaignRaisedIncludingConversion) internal view returns (bool) {
        if(endCampaignOnceGoalReached == true) {
            require(campaignRaisedIncludingConversion <= campaignHardCapWei.add(minContributionAmountWei)); //small GAP
        }
        return true;
    }

    function updateRaisedFundsAndValidateConversionInTermsOfHardCap(uint conversionAmountCampaignCurrency, bool isFiatConversion) internal returns (bool) {
        uint newTotalRaisedFunds = campaignRaisedIncludingPendingConversions.add(conversionAmountCampaignCurrency);
        require(canConversionBeCreatedInTermsOfHardCap(newTotalRaisedFunds)); // checking that criteria is satisfied
        updateTotalRaisedFunds(newTotalRaisedFunds); //updating new total raised funds
        return true;
    }

    function canConversionBeCreatedInTermsOfMinMaxContribution(address converter, uint amountWillingToSpend, bool isFiat) internal view returns (bool) {
        bool canConvert;
        if(isFiat) {
            (canConvert,)= validateMinMaxContributionForFIATConversion(converter, amountWillingToSpend);
        } else {
            (canConvert,) = validateMinMaxContributionForETHConversion(converter, amountWillingToSpend);
        }
        return canConvert;
    }

    function validateMinMaxContributionForFIATConversion(address converter, uint amountWillingToSpendFiatWei) internal view returns (bool,uint) {
        uint alreadySpentETHWei;
        uint alreadySpentFIATWEI;
        if(keccak256(currency) == keccak256('ETH')) {
            return (false, 0);
        } else {
            (alreadySpentETHWei,alreadySpentFIATWEI,) = ITwoKeyConversionHandler(conversionHandler).getConverterPurchasesStats(converter);

            uint leftToSpendFiat = checkHowMuchUserCanConvert(alreadySpentETHWei,alreadySpentFIATWEI);
            if(leftToSpendFiat >= amountWillingToSpendFiatWei && minContributionAmountWei <= amountWillingToSpendFiatWei) {
                return (true,leftToSpendFiat);
            } else {
                return (false,leftToSpendFiat);
            }
        }
    }

    function validateMinMaxContributionForETHConversion(address converter, uint amountWillingToSpendEthWei) public view returns (bool,uint) {
        uint alreadySpentETHWei;
        uint alreadySpentFIATWEI;
        (alreadySpentETHWei,alreadySpentFIATWEI,) = ITwoKeyConversionHandler(conversionHandler).getConverterPurchasesStats(converter);
        uint leftToSpend = checkHowMuchUserCanConvert(alreadySpentETHWei, alreadySpentFIATWEI);

        if(keccak256(currency) == keccak256('ETH')) {
            //Adding a deviation of 1000 weis
            if(leftToSpend.add(1000) > amountWillingToSpendEthWei && minContributionAmountWei <= amountWillingToSpendEthWei) {
                return(true, leftToSpend);
            } else {
                return(false, leftToSpend);
            }
        } else {
            uint rate = getRateFromExchange();
            uint amountToBeSpentInFiat = (amountWillingToSpendEthWei.mul(rate)).div(10**18);
            // Adding gap 1%
            if(leftToSpend.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18)) >= amountToBeSpentInFiat &&
                minContributionAmountWei <= amountToBeSpentInFiat.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18))
            ) {
                return (true,leftToSpend);
            } else {
                return (false,leftToSpend);
            }
        }
    }


    /**
     * @notice Function to check if campaign has ended
     */
    function isCampaignEnded() internal view returns (bool) {
        if(checkIsCampaignActiveInTermsOfTime() == false) {
            return true;
        }
        if(endCampaignOnceGoalReached == true && campaignRaisedIncludingPendingConversions.add(minContributionAmountWei) >= campaignHardCapWei) {
            return true;
        }
        return false;
    }

    /**
     * @notice Function to check if contractor can withdraw unsold tokens
     */
    function canContractorWithdrawUnsoldTokens() public view returns (bool) {
        return isCampaignEnded();
    }


    /**
     * @notice Function to get investment rules
     * @return tuple containing if investment amount is fixed
     */
    function getInvestmentRules()
    public
    view
    returns (bool,uint,bool)
    {
        return (
            isFixedInvestmentAmount,
            campaignHardCapWei,
            endCampaignOnceGoalReached
        );
    }

    /**
     * @notice Function which will calculate the base amount, bonus amount
     * @param conversionAmountETHWeiOrFiat is amount of eth in conversion
     * @return tuple containing (base,bonus)
     */
    function getEstimatedTokenAmount(
        uint conversionAmountETHWeiOrFiat,
        bool isFiatConversion
    )
    public
    view
    returns (uint, uint)
    {
        uint value = pricePerUnitInETHWeiOrUSD;
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;
        if(isFiatConversion == true) {
            baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.mul(10**18).div(value);
            bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
            return (baseTokensForConverterUnits, bonusTokensForConverterUnits);
        } else {
            if(keccak256(currency) != keccak256('ETH')) {
                address ethUSDExchangeContract = getAddressFromRegistry("TwoKeyExchangeRateContract");
                uint rate = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getBaseToTargetRate(currency);

                conversionAmountETHWeiOrFiat = (conversionAmountETHWeiOrFiat.mul(rate)).div(10 ** 18); //converting eth to $wei
            }
        }

        baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.mul(10 ** unit_decimals).div(value);
        bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
        return (baseTokensForConverterUnits, bonusTokensForConverterUnits);
    }

    /**
     * @notice Get all constants from the contract
     * @return all constants from the contract
     */
    function getConstantInfo()
    public
    view
    returns (uint,uint,uint,uint,uint,uint,uint)
    {
        return (
            campaignStartTime,
            campaignEndTime,
            minContributionAmountWei,
            maxContributionAmountWei,
            unit_decimals,
            pricePerUnitInETHWeiOrUSD,
            maxConverterBonusPercent
        );
    }


    /**
     * @notice Function to fetch stats for the address
     */
    function getAddressStatistic(
        address _address,
        bool plasma
    )
    internal
    view
    returns (bytes)
    {
        bytes32 state; // NOT-EXISTING AS CONVERTER DEFAULT STATE

        address eth_address = ethereumOf(_address);
        address plasma_address = plasmaOf(_address);

        if(_address == contractor) {
            return abi.encodePacked(0, 0, 0, false, false);
        } else {
            bool isConverter;
            bool isReferrer;
            uint unitsConverterBought;
            uint amountConverterSpent;
            uint amountConverterSpentFIAT;

            (amountConverterSpent,amountConverterSpentFIAT, unitsConverterBought) = ITwoKeyConversionHandler(conversionHandler).getConverterPurchasesStats(eth_address);
            if(unitsConverterBought> 0) {
                isConverter = true;
                state = ITwoKeyConversionHandler(conversionHandler).getStateForConverter(eth_address);
            }
            if(referrerPlasma2TotalEarnings2key[plasma_address] > 0) {
                isReferrer = true;
            }

            return abi.encodePacked(
                amountConverterSpent,
                referrerPlasma2TotalEarnings2key[plasma_address],
                unitsConverterBought,
                isConverter,
                isReferrer,
                state
            );
        }
    }

}
