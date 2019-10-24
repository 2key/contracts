pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaignConversionHandler.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../interfaces/ITwoKeyBaseReputationRegistry.sol";
import "../interfaces/ITwoKeyPurchasesHandler.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionHandler is UpgradeableCampaign, TwoKeyCampaignConversionHandler{

    bool public isFiatConversionAutomaticallyApproved;
    bool isKYCRequired;

    Conversion[] conversions;
    ITwoKeyAcquisitionCampaignERC20 twoKeyCampaign;

    mapping(address => uint256) private amountConverterSpentFiatWei; // Amount converter spent for Fiat conversions
    mapping(address => uint256) private unitsConverterBought; // Number of units (ERC20 tokens) bought


    address assetContractERC20;


    /// Structure which will represent conversion
    struct Conversion {
        address contractor; // Contractor (creator) of campaign
        uint256 contractorProceedsETHWei; // How much contractor will receive for this conversion
        address converter; // Converter is one who's buying tokens -> plasma address
        ConversionState state;
        uint256 conversionAmount; // Amount for conversion (In ETH / FIAT)
        uint256 maxReferralRewardETHWei; // Total referral reward for the conversion
        uint256 maxReferralReward2key;
        uint256 moderatorFeeETHWei;
        uint256 baseTokenUnits;
        uint256 bonusTokenUnits;
        uint256 conversionCreatedAt; // When conversion is created
        uint256 conversionExpiresAt; // When conversion expires
        bool isConversionFiat;
    }

    function setInitialParamsConversionHandler(
        uint [] values,
        address _twoKeyAcquisitionCampaignERC20,
        address _twoKeyPurchasesHandler,
        address _contractor,
        address _assetContractERC20,
        address _twoKeySingletonRegistry
    )
    public
    {
        require(isCampaignInitialized == false);
        counters = new uint[](10);

        expiryConversionInHours = values[0];

        if(values[1] == 1) {
            isFiatConversionAutomaticallyApproved = true;
        }

        if(values[8] == 1) {
            isKYCRequired = true;
        }

        // Instance of interface
        twoKeyPurchasesHandler = _twoKeyPurchasesHandler;
        twoKeyCampaign = ITwoKeyAcquisitionCampaignERC20(_twoKeyAcquisitionCampaignERC20);

        twoKeySingletonRegistry = _twoKeySingletonRegistry;
        contractor = _contractor;
        assetContractERC20 =_assetContractERC20;
        twoKeyEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource");
        twoKeyBaseReputationRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyBaseReputationRegistry");
        isCampaignInitialized = true;
    }



    function emitExecutedEvent(
        address _converterAddress,
        uint conversionId,
        uint tokens
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).executedV1(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(_converterAddress),
            conversionId,
            tokens
        );
    }

    function emitRejectedEvent(
        address _campaignAddress,
        address _converterAddress
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).rejected(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(_converterAddress)
        );
    }

    function emitConvertedEvent(
        address converterAddress,
        uint baseTokens,
        uint bonusTokens,
        uint conversionAmount,
        bool isFiatConversion,
        uint conversionId
    )
    internal
    view
    {
        ITwoKeyEventSource(twoKeyEventSource).convertedAcquisitionV2(
            twoKeyCampaign,
            ITwoKeyEventSource(twoKeyEventSource).plasmaOf(converterAddress),
            baseTokens,
            bonusTokens,
            conversionAmount,
            isFiatConversion,
            conversionId
        );
    }



    /// @notice Support function to create conversion
    /// @dev This function can only be called from TwoKeyAcquisitionCampaign contract address
    /// @param _converterAddress is the address of the converter
    /// @param _conversionAmount is the amount for conversion in ETH
    function supportForCreateConversion(
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        uint256 baseTokensForConverterUnits,
        uint256 bonusTokensForConverterUnits,
        bool isConversionFiat,
        bool _isAnonymous,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint)
    {
        require(msg.sender == address(twoKeyCampaign));

        //If KYC is required, basic funnel executes and we require that converter is not previously rejected
        if(isKYCRequired == true) {
            require(converterToState[_converterAddress] != ConverterState.REJECTED); // If converter is rejected then can't create conversion
            // Checking the state for converter, if this is his 1st time, he goes initially to PENDING_APPROVAL
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
                stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
            }
        } else {
            //If KYC is not required converter is automatically approved
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.APPROVED;
                stateToConverter[bytes32("APPROVED")].push(_converterAddress);
            }
        }

        // Set if converter want to be anonymous
        isConverterAnonymous[_converterAddress] = _isAnonymous;


        uint _moderatorFeeETHWei = 0;
        uint256 _contractorProceeds = _conversionAmount; //In case of fiat conversion, this is going to be fiat value

        ConversionState state;

        if(isConversionFiat == false) {
            _moderatorFeeETHWei = calculateModeratorFee(_conversionAmount);
            _contractorProceeds = _conversionAmount.sub(_maxReferralRewardETHWei.add(_moderatorFeeETHWei));
            //TODO: Add accounting for fiat proceeds
            state = ConversionState.APPROVED; // All eth conversions are auto approved
            counters[1] = counters[1].add(1);
        } else {
            //This means fiat conversion is automatically approved
            if(isFiatConversionAutomaticallyApproved) {
                state = ConversionState.APPROVED;
                counters[1] = counters[1].add(1); // Increase the number of approved conversions
            } else {
                state = ConversionState.PENDING_APPROVAL; // Fiat conversion state is PENDING_APPROVAL
                counters[0] = counters[0].add(1); // If conversion is FIAT it will be always first pending and will have to be approved
            }
        }

        Conversion memory c = Conversion(contractor, _contractorProceeds, _converterAddress,
            state ,_conversionAmount, _maxReferralRewardETHWei, 0, _moderatorFeeETHWei, baseTokensForConverterUnits,
            bonusTokensForConverterUnits,
            now, now.add(expiryConversionInHours.mul(1 hours)), isConversionFiat);

        conversions.push(c);

        converterToHisConversions[_converterAddress].push(numberOfConversions);

        conversionToCampaignCurrencyAmountAtTimeOfCreation[numberOfConversions] = conversionAmountCampaignCurrency;

        emitConvertedEvent(
            _converterAddress,
            baseTokensForConverterUnits,
            bonusTokensForConverterUnits,
            _conversionAmount,
            isConversionFiat,
            numberOfConversions
        );

        emit ConversionCreated(numberOfConversions);

        numberOfConversions = numberOfConversions.add(1);

        return numberOfConversions - 1;
    }


    /**
     * @notice Function to perform all the logic which has to be done when we're performing conversion
     * @param _conversionId is the id
     */
    function executeConversion(
        uint _conversionId
    )
    public
    {
        Conversion conversion = conversions[_conversionId];

        uint totalUnits = conversion.baseTokenUnits.add(conversion.bonusTokenUnits);

        // Converter must be approved in all cases
        require(converterToState[conversion.converter] == ConverterState.APPROVED);

        if(conversion.isConversionFiat == true) {
            if(isFiatConversionAutomaticallyApproved) {
                counters[1] = counters[1].sub(1); // Decrease number of approved conversions
            } else {
                require(conversion.state == ConversionState.PENDING_APPROVAL);
                require(msg.sender == contractor); // first check who calls this in order to save gas
//                uint availableTokens = twoKeyAcquisitionCampaignERC20.getAvailableAndNonReservedTokensAmount();
//                require(totalUnits < availableTokens);
                //Sufficient because we reserve tokens at the time of creation, in case we bought all, we'll get 0 which will always throw
                counters[0] = counters[0].sub(1); //Decrease number of pending conversions
            }

            //Update raised funds FIAT once the conversion is executed
            counters[9] = counters[9].add(conversion.conversionAmount);

            //Update amount converter spent in FIAT
            amountConverterSpentFiatWei[conversion.converter] = amountConverterSpentFiatWei[conversion.converter].add(conversion.conversionAmount);
        } else {
            require(conversion.state == ConversionState.APPROVED);
            amountConverterSpentEthWEI[conversion.converter] = amountConverterSpentEthWEI[conversion.converter].add(conversion.conversionAmount);
            counters[1] = counters[1].sub(1); //Decrease number of approved conversions
        }
        //Update bought units
        unitsConverterBought[conversion.converter] = unitsConverterBought[conversion.converter].add(conversion.baseTokenUnits).add(conversion.bonusTokenUnits);

        // Total rewards for referrers
        uint totalReward2keys = 0;

        // Buy tokens from campaign and distribute rewards between referrers
        totalReward2keys = twoKeyCampaign.buyTokensAndDistributeReferrerRewards(
            conversion.maxReferralRewardETHWei,
            conversion.converter,
            _conversionId,
            conversion.isConversionFiat
        );

        //Update reputation points in registry for conversion executed event
        ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionExecutedEvent(
            conversion.converter,
            contractor,
            twoKeyCampaign
        );

        // Add total rewards
        counters[8] = counters[8].add(totalReward2keys);

        // update reserved amount of tokens on acquisition contract
        twoKeyCampaign.updateReservedAmountOfTokensIfConversionRejectedOrExecuted(totalUnits);

        //Update total raised funds
        if(conversion.isConversionFiat == false) {
            // update moderator balances
            twoKeyCampaign.buyTokensForModeratorRewards(conversion.moderatorFeeETHWei);
            // update contractor proceeds
            twoKeyCampaign.updateContractorProceeds(conversion.contractorProceedsETHWei);
            // add conversion amount to counter
            counters[6] = counters[6].add(conversion.conversionAmount);
        }

        if(doesConverterHaveExecutedConversions[conversion.converter] == false) {
            counters[5] = counters[5].add(1); //increase number of unique converters
            doesConverterHaveExecutedConversions[conversion.converter] = true;
        }

        ITwoKeyPurchasesHandler(twoKeyPurchasesHandler).startVesting(
            conversion.baseTokenUnits,
            conversion.bonusTokenUnits,
            _conversionId,
            conversion.converter
        );

        // Transfer tokens to lockup contract
        twoKeyCampaign.moveFungibleAsset(address(twoKeyPurchasesHandler), totalUnits);
        campaignRaised = campaignRaised.add(conversionToCampaignCurrencyAmountAtTimeOfCreation[_conversionId]);
        conversion.maxReferralReward2key = totalReward2keys;
        conversion.state = ConversionState.EXECUTED;
        counters[3] = counters[3].add(1); //Increase number of executed conversions
        counters[7] = counters[7].add(totalUnits); //update sold tokens once conversion is executed

        emitExecutedEvent(conversion.converter, _conversionId, conversion.baseTokenUnits.add(conversion.bonusTokenUnits));
    }


    /**
     * @notice Function to get conversion details by id
     * @param conversionId is the id of conversion
     */
    function getConversion(
        uint conversionId
    )
    external
    view
    returns (bytes)
    {
        Conversion memory conversion = conversions[conversionId];
        address empty = address(0);
        if(isConverterAnonymous[conversion.converter] == false) {
            empty = conversion.converter;
        }
        return abi.encodePacked (
            conversion.contractor,
            conversion.contractorProceedsETHWei,
            empty,
            conversion.state,
            conversion.conversionAmount,
            conversion.maxReferralRewardETHWei,
            conversion.maxReferralReward2key,
            conversion.moderatorFeeETHWei,
            conversion.baseTokenUnits,
            conversion.bonusTokenUnits,
            conversion.conversionCreatedAt,
            conversion.conversionExpiresAt,
            conversion.isConversionFiat
        );
    }


    /// @notice Function where we can reject converter
    /// @dev only maintainer or contractor can call this function
    /// @param _converter is the address of converter
    function rejectConverter(
        address _converter
    )
    public
    onlyContractorOrMaintainer
    {
        rejectConverterInternal(_converter);
        uint reservedAmount = 0;
        uint refundAmount = 0;
        uint len = converterToHisConversions[_converter].length;
        for(uint i=0; i< len; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion c = conversions[conversionId];
            if(c.state == ConversionState.PENDING_APPROVAL || c.state == ConversionState.APPROVED) {
                if(c.state == ConversionState.PENDING_APPROVAL) {
                    counters[0] = counters[0].sub(1); //Reduce number of pending conversions
                } else {
                    counters[1] = counters[1].sub(1); //Reduce number of approved conversions
                }
                counters[2] = counters[2].add(1); //Increase number of rejected conversions
                ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionRejectedEvent(_converter, contractor, twoKeyCampaign);
                c.state = ConversionState.REJECTED;
                reservedAmount += c.baseTokenUnits.add(c.bonusTokenUnits);
                if(c.isConversionFiat == false) {
                    refundAmount = refundAmount.add(c.conversionAmount);
                }
            }
        }
        //If there's an amount to be returned and reserved tokens, update state and execute cashback
        if(reservedAmount > 0 && refundAmount > 0) {
            twoKeyCampaign.updateReservedAmountOfTokensIfConversionRejectedOrExecuted(reservedAmount);
            twoKeyCampaign.sendBackEthWhenConversionCancelledOrRejected(_converter, refundAmount);
        }

        emitRejectedEvent(twoKeyCampaign, _converter);
    }


    /**
     * @notice Function to cancel conversion and get back money
     * @param _conversionId is the id of the conversion
     * @dev returns all the funds to the converter back
     */
    function converterCancelConversion(
        uint _conversionId
    )
    external
    {
        Conversion conversion = conversions[_conversionId];

        require(conversion.conversionExpiresAt > block.timestamp);
        require(msg.sender == conversion.converter);
        require(conversion.state == ConversionState.PENDING_APPROVAL);

        counters[0] = counters[0].sub(1); // Reduce number of pending conversions
        counters[4] = counters[4].add(1); // Increase number of cancelled conversions
        conversion.state = ConversionState.CANCELLED_BY_CONVERTER;

        uint tokensToRefund = conversion.baseTokenUnits.add(conversion.bonusTokenUnits);

        twoKeyCampaign.updateReservedAmountOfTokensIfConversionRejectedOrExecuted(tokensToRefund);
        twoKeyCampaign.sendBackEthWhenConversionCancelledOrRejected(msg.sender, conversion.conversionAmount);
    }

    /**
     * @notice Function to fetch how much user spent money and bought units in total
     * @param _converter is the converter we're checking this information for
     */
    function getConverterPurchasesStats(
        address _converter
    )
    public
    view
    returns (uint,uint,uint)
    {
        return (
            amountConverterSpentEthWEI[_converter],
            amountConverterSpentFiatWei[_converter],
            unitsConverterBought[_converter]
        );
    }


}
