pragma solidity ^0.4.24;
import "../TwoKeyConversionStates.sol";
import "../TwoKeyConverterStates.sol";

import "../singleton-contracts/TwoKeyLockupContract.sol";


import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyBaseReputationRegistry.sol";
import "../libraries/SafeMath.sol";
import "../Upgradeable.sol";

/**
 * @notice Contract to handle logic related for Acquisition
 * @dev There will be 1 conversion handler per Acquisition Campaign
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionHandler is Upgradeable, TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint256;

    bool isCampaignInitialized;

    bool public isFiatConversionAutomaticallyApproved;

    event ConversionCreated(uint conversionId);
    uint numberOfConversions;

    /**
     * This array will represent counter values where position will be index (which counter) and value will be actual counter value
     * counters[0] = PENDING_CONVERSIONS
     * counters[1] = APPROVED_CONVERSIONS
     * counters[2] = REJECTED_CONVERSIONS
     * counters[3] = EXECUTED_CONVERSIONS
     * counters[4] = CANCELLED_CONVERSIONS
     * counters[5] = UNIQUE_CONVERTERS
     * counters[6] = RAISED_FUNDS_ETH_WEI
     * counters[7] = TOKENS_SOLD
     * counters[8] = TOTAL_BOUNTY
     * counters[9] = RAISED_FUNDS_FIAT_WEI
     */
    uint [] counters;

    uint256 expiryConversionInHours; // How long converter can be pending before it will be automatically rejected and funds will be returned to convertor (hours)

    Conversion[] conversions;


    mapping(bytes32 => address[]) stateToConverter; //State to all converters in that state
    mapping(address => uint[]) converterToHisConversions;

    mapping(address => ConverterState) converterToState; //Converter to his state
    mapping(address => bool) isConverterAnonymous;
    mapping(address => address[]) converterToLockupContracts;


    address twoKeyEventSource;
    ITwoKeyAcquisitionCampaignERC20 twoKeyAcquisitionCampaignERC20;
    address contractor;
    address assetContractERC20;
    address twoKeyBaseReputationRegistry;

    uint tokenDistributionDate; // January 1st 2019
    uint maxDistributionDateShiftInDays; // 180 days
    uint bonusTokensVestingMonths; // 6 months
    uint bonusTokensVestingStartShiftInDaysFromDistributionDate; // 180 days


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
        address lockupAddress;
    }

    modifier onlyContractorOrMaintainer {
        require(msg.sender == contractor || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender));
        _;
    }


    function setInitialParamsConversionHandler(
        uint [] values,
        address _twoKeyAcquisitionCampaignERC20,
        address _contractor,
        address _assetContractERC20,
        address _twoKeyEventSource,
        address _twoKeyBaseReputationRegistry
    )
    public
    {
        require(isCampaignInitialized == false);
        counters = new uint[](10);

        expiryConversionInHours = values[0];
        tokenDistributionDate = values[1];
        maxDistributionDateShiftInDays = values[2];
        bonusTokensVestingMonths = values[3];
        bonusTokensVestingStartShiftInDaysFromDistributionDate = values[4];

        // 5th argument will represent if FIAT conversion is automatically approved
        if(values[5] == 1) {
            isFiatConversionAutomaticallyApproved = true;
        }
        // Instance of interface
        twoKeyAcquisitionCampaignERC20 = ITwoKeyAcquisitionCampaignERC20(_twoKeyAcquisitionCampaignERC20);

        contractor = _contractor;
        assetContractERC20 =_assetContractERC20;
        twoKeyEventSource = _twoKeyEventSource;
        twoKeyBaseReputationRegistry = _twoKeyBaseReputationRegistry;
        isCampaignInitialized = true;
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(
        uint256 _conversionAmountETHWei
    )
    private
    view
    returns (uint256)
    {
        uint256 fee = _conversionAmountETHWei.mul(ITwoKeyEventSource(twoKeyEventSource).getTwoKeyDefaultIntegratorFeeFromAdmin()).div(100);
        return fee;
    }


    /// @notice Support function to create conversion
    /// @dev This function can only be called from TwoKeyAcquisitionCampaign contract address
    /// @param _contractor is the address of campaign contractor
    /// @param _converterAddress is the address of the converter
    /// @param _conversionAmount is the amount for conversion in ETH
    function supportForCreateConversion(
        address _contractor,
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        uint256 baseTokensForConverterUnits,
        uint256 bonusTokensForConverterUnits,
        bool isConversionFiat,
        bool _isAnonymous,
        bool _isKYCRequired
    )
    public
    returns (uint)
    {
        require(msg.sender == address(twoKeyAcquisitionCampaignERC20));

        //If KYC is required, basic funnel executes and we require that converter is not previously rejected
        if(_isKYCRequired == true) {
            require(converterToState[_converterAddress] != ConverterState.REJECTED); // If converter is rejected then can't create conversion
        } else {
            //If this is his 1st time, we immediatelly approve him, otherwise he will always be approved after 1st time
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
            _contractorProceeds = _conversionAmount - _maxReferralRewardETHWei - _moderatorFeeETHWei;
            //Determine state and increment counters
            if(converterToState[_converterAddress] == ConverterState.APPROVED) {
                state = ConversionState.APPROVED;
                counters[1]++; //Increase number of approved conversions
            } else if (converterToState[_converterAddress] == ConverterState.REJECTED) {
                state = ConversionState.REJECTED;
                counters[2]++; //Increase number of rejected conversions
            } else {
                state = ConversionState.PENDING_APPROVAL;
                counters[0]++;
            }
        } else {
            //This means fiat conversion is automatically approved
            if(isFiatConversionAutomaticallyApproved) {
                state = ConversionState.APPROVED;
                counters[1] ++; // Increase the number of approved conversions
            } else {
                state = ConversionState.PENDING_APPROVAL;
                counters[0]++; // If conversion is FIAT it will be always first pending and will have to be approved
            }
        }

        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress,
            state ,_conversionAmount, _maxReferralRewardETHWei, 0, _moderatorFeeETHWei, baseTokensForConverterUnits,
            bonusTokensForConverterUnits,
            now, now + expiryConversionInHours * (1 hours), isConversionFiat, 0x0);

        conversions.push(c);

        converterToHisConversions[_converterAddress].push(numberOfConversions);
        emit ConversionCreated(numberOfConversions);
        numberOfConversions++;

        // Checking the state for converter, if this is his 1st time, he goes initially to PENDING_APPROVAL
        if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
            converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
            stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
        }

        return numberOfConversions-1;
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

        uint totalUnits = conversion.baseTokenUnits + conversion.bonusTokenUnits;

        if(conversion.isConversionFiat == true) {
            if(isFiatConversionAutomaticallyApproved) {
                require(conversion.state == ConversionState.APPROVED);
                counters[1] --; // Decrease number of approved conversions
            } else {
                require(conversion.state == ConversionState.PENDING_APPROVAL);
                require(msg.sender == contractor); // first check who calls this in order to save gas
                uint availableTokens = twoKeyAcquisitionCampaignERC20.getAvailableAndNonReservedTokensAmount();
                require(totalUnits < availableTokens);
                counters[0]--; //Decrease number of pending conversions
            }

            //Update raised funds FIAT once the conversion is executed
            counters[9] = counters[9].add(conversion.conversionAmount);
        } else {
            //TODO uncomment
//            require(msg.sender == conversion.converter || msg.sender == contractor);
            require(conversion.state == ConversionState.APPROVED);
            counters[1]--; //Decrease number of approved conversions
        }

        /**
         * Deploy Lockup contract
         */
        TwoKeyLockupContract lockupContract = new TwoKeyLockupContract(bonusTokensVestingStartShiftInDaysFromDistributionDate, bonusTokensVestingMonths, tokenDistributionDate, maxDistributionDateShiftInDays,
            conversion.baseTokenUnits, conversion.bonusTokenUnits, _conversionId, conversion.converter, conversion.contractor, assetContractERC20, twoKeyEventSource);


        //Add lockup address to conversion object
        conversion.lockupAddress = address(lockupContract);

        // Transfer tokens to lockup contract
        twoKeyAcquisitionCampaignERC20.moveFungibleAsset(address(lockupContract), totalUnits);

        // Total rewards for referrers
        uint totalReward2keys = 0;

        //Update total raised funds
        if(conversion.isConversionFiat == false) {
            // Update reputation points in registry for conversion executed event
            ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionExecutedEvent(conversion.converter, contractor, twoKeyAcquisitionCampaignERC20);

            // Buy tokens from campaign and distribute rewards between referrers
            totalReward2keys = twoKeyAcquisitionCampaignERC20.buyTokensAndDistributeReferrerRewards(conversion.maxReferralRewardETHWei, conversion.converter, _conversionId);

            // Add total rewards
            counters[8] = counters[8].add(totalReward2keys);

            // update moderator balances
            twoKeyAcquisitionCampaignERC20.buyTokensForModeratorRewards(conversion.moderatorFeeETHWei);

            // update reserved amount of tokens on acquisition contract
            twoKeyAcquisitionCampaignERC20.updateReservedAmountOfTokensIfConversionRejectedOrExecuted(totalUnits);

            // update contractor proceeds
            twoKeyAcquisitionCampaignERC20.updateContractorProceeds(conversion.contractorProceedsETHWei);

            // add conversion amount to counter
            counters[6] = counters[6].add(conversion.conversionAmount);

        }

        if(converterToLockupContracts[conversion.converter].length == 0) {
            counters[5]++; // Increase number of unique converters
        }

        conversion.maxReferralReward2key = totalReward2keys;
        conversion.state = ConversionState.EXECUTED;
        converterToLockupContracts[conversion.converter].push(lockupContract);
        counters[3]++; //Increase number of executed conversions
        counters[7] = counters[7].add(totalUnits); //update sold tokens once conversion is executed
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
            conversion.isConversionFiat,
            conversion.lockupAddress
        );
    }


    function getAllConvertersPerState(
        bytes32 state
    )
    public
    view
    onlyContractorOrMaintainer
    returns (address[])
    {
        return stateToConverter[state];
    }


    /// @notice Function to get array of lockup contract addresses for converter
    /// @dev only contractor or maintainer can call this function
    /// @param _converter is the address of converter
    /// @return array of addresses
    function getLockupContractsForConverter(
        address _converter
    )
    public
    view
    returns (address[])
    {
        require(msg.sender == contractor || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender) || msg.sender == _converter);
        return converterToLockupContracts[_converter];
    }


    /// @notice Function to move converter address from stateA to stateB
    /// @param _converter is the address of converter
    /// @param destinationState is the state we'd like to move converter to
    function moveFromStateAToStateB(
        address _converter,
        bytes32 destinationState
    )
    internal
    {
        ConverterState state = converterToState[_converter];
        bytes32 key = convertConverterStateToBytes(state);
        address[] memory pending = stateToConverter[key];
        for(uint i=0; i< pending.length; i++) {
            if(pending[i] == _converter) {
                stateToConverter[destinationState].push(_converter);
                pending[i] = pending[pending.length-1];
                delete pending[pending.length-1];
                stateToConverter[key] = pending;
                stateToConverter[key].length--;
                break;
            }
        }
    }


    /// @notice Function where we can change state of converter to Approved
    /// @dev Converter can only be approved if his previous state is pending or rejected
    /// @param _converter is the address of converter
    function moveFromPendingOrRejectedToApprovedState(
        address _converter
    )
    internal
    {
        bytes32 destination = bytes32("APPROVED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.APPROVED;
    }


    /// @notice Function where we're going to move state of conversion from pending to rejected
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromPendingToRejectedState(
        address _converter
    )
    internal
    {
        bytes32 destination = bytes32("REJECTED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.REJECTED;
    }


    /// @notice Function where we are approving converter
    /// @dev only maintainer or contractor can call this method
    /// @param _converter is the address of converter
    function approveConverter(
        address _converter
    )
    public
    onlyContractorOrMaintainer
    {
        uint len = converterToHisConversions[_converter].length;
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        for(uint i=0; i<len; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion c = conversions[conversionId];
            if(c.state == ConversionState.PENDING_APPROVAL && c.isConversionFiat == false) {
                counters[0]--; //Reduce number of pending conversions
                counters[1]++; //Increase number of approved conversions
                c.state = ConversionState.APPROVED;
//                conversions[conversionId] = c;
            }
        }
        moveFromPendingOrRejectedToApprovedState(_converter);
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
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingToRejectedState(_converter);
        uint reservedAmount = 0;
        uint refundAmount = 0;
        for(uint i=0; i<converterToHisConversions[_converter].length; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion c = conversions[conversionId];
            if(c.state == ConversionState.PENDING_APPROVAL) {
                counters[0]--; //Reduce number of pending conversions
                counters[2]++; //Increase number of rejected conversions
                ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionRejectedEvent(_converter, contractor, twoKeyAcquisitionCampaignERC20);
                c.state = ConversionState.REJECTED;
//                conversions[conversionId] = c;
                reservedAmount += c.baseTokenUnits + c.bonusTokenUnits;
                refundAmount += c.conversionAmount;
            }
        }
        //If there's an amount to be returned and reserved tokens, update state and execute cashback
        if(reservedAmount > 0 && refundAmount > 0) {
            twoKeyAcquisitionCampaignERC20.updateReservedAmountOfTokensIfConversionRejectedOrExecuted(reservedAmount);
            twoKeyAcquisitionCampaignERC20.sendBackEthWhenConversionCancelled(_converter, refundAmount);
        }
    }


    /**
     * @notice Function to get all conversion ids for the converter
     * @param _converter is the address of the converter
     * @return array of conversion ids
     * @dev can only be called by converter itself or maintainer/contractor
     */
    function getConverterConversionIds(
        address _converter
    )
    public
    view
    returns (uint[])
    {
//        require(msg.sender == contractor || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender) || msg.sender == _converter);
        return converterToHisConversions[_converter];
    }

    function getLastConverterConversionId(
        address _converter
    )
    public
    view
    returns (uint)
    {
        return converterToHisConversions[_converter][converterToHisConversions[_converter].length - 1];
    }


    /**
     * @notice Function to get number of conversions
     * @dev Can only be called by contractor or maintainer
     */
    function getNumberOfConversions()
    external
    view
    returns (uint)
    {
        return numberOfConversions;
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

        require(conversion.conversionCreatedAt + 10*(1 days) < block.timestamp);
        require(msg.sender == conversion.converter);
        require(conversion.state == ConversionState.PENDING_APPROVAL);

        counters[0]--; // Reduce number of pending conversions
        counters[4]++; // Increase number of cancelled conversions
        conversion.state = ConversionState.CANCELLED_BY_CONVERTER;
        twoKeyAcquisitionCampaignERC20.sendBackEthWhenConversionCancelled(msg.sender, conversion.conversionAmount);
    }

    /**
     * @notice Get's number of converters per type, and returns tuple, as well as total raised funds
     getCampaignSummary
     */
    function getCampaignSummary()
    public
    view
    returns (uint,uint,uint,uint[])
    {
        bytes32 pending = convertConverterStateToBytes(ConverterState.PENDING_APPROVAL);
        bytes32 approved = convertConverterStateToBytes(ConverterState.APPROVED);
        bytes32 rejected = convertConverterStateToBytes(ConverterState.REJECTED);

        uint numberOfPending = stateToConverter[pending].length;
        uint numberOfApproved = stateToConverter[approved].length;
        uint numberOfRejected = stateToConverter[rejected].length;

        return (
            numberOfPending,
            numberOfApproved,
            numberOfRejected,
            counters
        );
    }

    /**
     * @notice Fuunction where contractro/converter or mdoerator can see the lockup address for conversion
     * @param _conversionId is the id of conversion requested
     */
    function getLockupContractAddress(
        uint _conversionId
    )
    public
    view
    returns (address)
    {
        Conversion memory c = conversions[_conversionId];
        require(msg.sender == contractor || msg.sender == c.converter || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender));
        return c.lockupAddress;
    }

    /**
     * @notice Function to get converter state
     * @param _converter is the address of the requested converter
     * @return hexed string of the state
     */
    function getStateForConverter(
        address _converter
    )
    external
    view
    returns (bytes32)
    {
        return convertConverterStateToBytes(converterToState[_converter]);
    }

}
