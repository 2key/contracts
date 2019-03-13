pragma solidity ^0.4.24;
import "../TwoKeyConversionStates.sol";
import "../TwoKeyConverterStates.sol";

import "../singleton-contracts/TwoKeyLockupContract.sol";


import "../interfaces/IERC20.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../interfaces/IUpgradableExchange.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyBaseReputationRegistry.sol";
import "../libraries/SafeMath.sol";

/**
 * @notice Contract to handle logic related for Acquisition
 * @dev There will be 1 conversion handler per Acquisition Campaign
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionHandler is TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint256;

    event ConversionCreated(uint indexed conversionId);
    uint tokensSold;
    uint raisedFundsEthWei;
    uint numberOfConversions;
    uint totalBounty;
    uint numberOfExecutedConversions;

    uint256 expiryConversionInHours; // How long converter can be pending before it will be automatically rejected and funds will be returned to convertor (hours)

    Conversion[] conversions;
    mapping(address => uint[]) converterToHisConversions;

    //State to all converters in that state
    mapping(bytes32 => address[]) stateToConverter;

    //Converter to his state
    mapping(address => ConverterState) converterToState;
    mapping(address => bool) isConverterAnonymous;
    mapping(address => address[]) converterToLockupContracts;

    mapping(uint => address) conversionId2LockupAddress;

    address twoKeyEventSource;
    address twoKeyAcquisitionCampaignERC20;
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
        uint256 conversionAmount; // Amount for conversion (In ETH)
        uint256 maxReferralRewardETHWei;
        uint256 moderatorFeeETHWei;
        uint256 baseTokenUnits;
        uint256 bonusTokenUnits;
        uint256 conversionCreatedAt; // When conversion is created
        uint256 conversionExpiresAt; // When conversion expires
        bool isConversionFiat;
    }

    /// @notice Modifier which allows only TwoKeyAcquisitionCampaign to issue calls
    modifier onlyTwoKeyAcquisitionCampaign() {
        require(msg.sender == address(twoKeyAcquisitionCampaignERC20));
        _;
    }

    modifier onlyContractorOrMaintainer {
        require(msg.sender == address(contractor) || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender));
        _;
    }


    modifier onlyApprovedConverter() {
        require(converterToState[msg.sender] == ConverterState.APPROVED);
        _;
    }


    /**
     * @notice Contstructor of the conversion handler contract
     * @param _tokenDistributionDate is the date of token distribution
     * @param _maxDistributionDateShiftInDays is the maximum distribution shift in days
     * @param _bonusTokensVestingMonths is the number of bonus token vesting months
     * @param _bonusTokensVestingStartShiftInDaysFromDistributionDate is
     */
    constructor(
        uint _expiryConversionInHours,
        uint _tokenDistributionDate, // January 1st 2019
        uint _maxDistributionDateShiftInDays, // 180 days
        uint _bonusTokensVestingMonths, // 6 months
        uint _bonusTokensVestingStartShiftInDaysFromDistributionDate
        ) public {
        expiryConversionInHours = _expiryConversionInHours;
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        bonusTokensVestingMonths = _bonusTokensVestingMonths;
        bonusTokensVestingStartShiftInDaysFromDistributionDate = _bonusTokensVestingStartShiftInDaysFromDistributionDate;
    }

    /// @notice Method which will be called inside constructor of TwoKeyAcquisitionCampaignERC20
    /// @param _twoKeyAcquisitionCampaignERC20 is the address of TwoKeyAcquisitionCampaignERC20 contract
    /// @param _contractor is the address of the contractor
    function setTwoKeyAcquisitionCampaignERC20(
        address _twoKeyAcquisitionCampaignERC20,
        address _contractor,
        address _assetContractERC20,
        address _twoKeyEventSource,
        address _twoKeyBaseReputationRegistry) public {
        require(twoKeyAcquisitionCampaignERC20 == address(0));
        twoKeyAcquisitionCampaignERC20 = _twoKeyAcquisitionCampaignERC20;
        contractor = _contractor;
        assetContractERC20 =_assetContractERC20;
        twoKeyEventSource = _twoKeyEventSource;
        twoKeyBaseReputationRegistry = _twoKeyBaseReputationRegistry;

    }


    /**
     * @notice Determine the state of conversion based on converter address
     * @param _converterAddress is the address of converter
     * @return state of conversion (enum)
     */
    function determineConversionState(address _converterAddress) private view returns (ConversionState) {
        ConversionState state = ConversionState.PENDING_APPROVAL;
        if(converterToState[_converterAddress] == ConverterState.APPROVED) {
            state = ConversionState.APPROVED;
        } else if (converterToState[_converterAddress] == ConverterState.REJECTED) {
            state = ConversionState.REJECTED;
        }
        return state;
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(uint256 _conversionAmountETHWei) private view returns (uint256)  {
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
        bool isConversionFiat
        ) public {
        require(msg.sender == twoKeyAcquisitionCampaignERC20);
        require(converterToState[_converterAddress] != ConverterState.REJECTED); // If converter is rejected then can't create conversion

        uint _moderatorFeeETHWei = 0;
        uint256 _contractorProceeds = _conversionAmount; //In case of fiat conversion, this is going to be fiat value
        ConversionState state = ConversionState.PENDING_APPROVAL;

        if(isConversionFiat == false) {
            _moderatorFeeETHWei = calculateModeratorFee(_conversionAmount);
            _contractorProceeds = _conversionAmount - _maxReferralRewardETHWei - _moderatorFeeETHWei;
            state = determineConversionState(_converterAddress);
        }

        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress,
            state ,_conversionAmount, _maxReferralRewardETHWei, _moderatorFeeETHWei, baseTokensForConverterUnits,
            bonusTokensForConverterUnits,
            now, now + expiryConversionInHours * (1 hours), isConversionFiat);

        conversions.push(c);
        converterToHisConversions[_converterAddress].push(numberOfConversions);
        emit ConversionCreated(numberOfConversions);
        numberOfConversions++;

        ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionCreatedEvent(_converterAddress, contractor, twoKeyAcquisitionCampaignERC20);
        if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
            converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
            stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
        }
    }

    /**
     * @notice Function to perform all the logic which has to be done when we're performing conversion
     * @param _conversionId is the id
     */

    function executeConversion(uint _conversionId) public {
        Conversion memory conversion = conversions[_conversionId];
        uint totalUnits = conversion.baseTokenUnits + conversion.bonusTokenUnits;
        if(conversion.isConversionFiat == true) {
            uint availableTokens = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).getAvailableAndNonReservedTokensAmount();
            require(totalUnits < availableTokens);
            require(conversion.state == ConversionState.PENDING_APPROVAL);
            require(msg.sender == contractor);
        } else {
            require(conversion.state == ConversionState.APPROVED);
            require(msg.sender == conversion.converter || msg.sender == contractor);
        }

        /**
         * For the lockup contracts there's no need to save to plasma address, there we'll save ethereum address
         */
        TwoKeyLockupContract lockupContract = new TwoKeyLockupContract(bonusTokensVestingStartShiftInDaysFromDistributionDate, bonusTokensVestingMonths, tokenDistributionDate, maxDistributionDateShiftInDays,
            conversion.baseTokenUnits, conversion.bonusTokenUnits, _conversionId, conversion.converter, conversion.contractor, assetContractERC20, twoKeyEventSource);

        conversionId2LockupAddress[_conversionId] = address(lockupContract);
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).moveFungibleAsset(address(lockupContract), totalUnits);

        conversion.state = ConversionState.EXECUTED;
        conversions[_conversionId] = conversion;
        converterToLockupContracts[conversion.converter].push(lockupContract);


        //Update total raised funds
        if(conversion.isConversionFiat == false) {
            ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionExecutedEvent(conversion.converter, contractor, twoKeyAcquisitionCampaignERC20);
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateRefchainRewards(conversion.maxReferralRewardETHWei, conversion.converter, _conversionId);
            totalBounty = totalBounty.add(conversion.maxReferralRewardETHWei);
            // update moderator balances
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateModeratorBalanceETHWei(conversion.moderatorFeeETHWei);
            raisedFundsEthWei = raisedFundsEthWei + conversion.conversionAmount;
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateReservedAmountOfTokensIfConversionRejectedOrExecuted(totalUnits);
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateContractorProceeds(conversion.contractorProceedsETHWei);
        }
        numberOfExecutedConversions++;
        tokensSold = tokensSold + totalUnits; //update sold tokens once conversion is executed
    }

    /**
     * @notice Function to get conversion details by id
     * @param conversionId is the id of conversion
     */
    function getConversion(
        uint conversionId
    ) external view returns (bytes) {
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
            conversion.moderatorFeeETHWei,
            conversion.baseTokenUnits,
            conversion.bonusTokenUnits,
            conversion.conversionCreatedAt,
            conversion.conversionExpiresAt,
            conversion.isConversionFiat
        );
    }


    /**
     * @notice Function where converter can say if he want's to be "anonymous" (not shown in the UI)
     * @param _converter is the converter address
     * @param _isAnonymous is his decision true/false
     */
    function setAnonymous(address _converter, bool _isAnonymous) external onlyTwoKeyAcquisitionCampaign {
        isConverterAnonymous[_converter] = _isAnonymous;
    }

    /// @notice Function to get all pending converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of pending converter addresses
    function getAllPendingConverters() public view onlyContractorOrMaintainer returns (address[]) {
        return (stateToConverter[bytes32("PENDING_APPROVAL")]);
    }

    /// @notice Function to get all rejected converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of rejected converter addresses
    function getAllRejectedConverters() public view onlyContractorOrMaintainer returns(address[]) {
        return stateToConverter[bytes32("REJECTED")];
    }


    /// @notice Function to get all approved converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of approved converter addresses
    function getAllApprovedConverters() public view onlyContractorOrMaintainer returns(address[]) {
        return stateToConverter[bytes32("APPROVED")];
    }


    /// @notice Function to get array of lockup contract addresses for converter
    /// @dev only contractor or maintainer can call this function
    /// @param _converter is the address of converter
    /// @return array of addresses
    function getLockupContractsForConverter(address _converter) public view returns (address[]){
        require(msg.sender == contractor || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender) || msg.sender == _converter);
        return converterToLockupContracts[_converter];
    }


    /// @notice Function to move converter address from stateA to stateB
    /// @param _converter is the address of converter
    /// @param destinationState is the state we'd like to move converter to
    function moveFromStateAToStateB(address _converter, bytes32 destinationState) internal {
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
    function moveFromPendingOrRejectedToApprovedState(address _converter) private {
        bytes32 destination = bytes32("APPROVED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.APPROVED;
    }

    /// @notice Function where we're going to move state of conversion from pending to rejected
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromPendingToRejectedState(address _converter) private {
        bytes32 destination = bytes32("REJECTED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.REJECTED;
    }


    /// @notice Function where we are approving converter
    /// @dev only maintainer or contractor can call this method
    /// @param _converter is the address of converter
    function approveConverter(address _converter) public onlyContractorOrMaintainer {
        uint len = converterToHisConversions[_converter].length;
        require(len> 0);
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL || converterToState[_converter] == ConverterState.REJECTED);
        for(uint i=0; i<len; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion memory c = conversions[conversionId];
            if(c.state == ConversionState.PENDING_APPROVAL && c.isConversionFiat == false) {
                c.state = ConversionState.APPROVED;
                conversions[conversionId] = c;
            }
        }
        moveFromPendingOrRejectedToApprovedState(_converter);
    }


    /// @notice Function where we can reject converter
    /// @dev only maintainer or contractor can call this function
    /// @param _converter is the address of converter
    function rejectConverter(address _converter) public onlyContractorOrMaintainer  {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingToRejectedState(_converter);
        uint reservedAmount = 0;
        uint refundAmount = 0;
        for(uint i=0; i<converterToHisConversions[_converter].length; i++) {
            uint conversionId = converterToHisConversions[_converter][i];
            Conversion memory c = conversions[conversionId];
            if(c.state == ConversionState.PENDING_APPROVAL) {
                ITwoKeyBaseReputationRegistry(twoKeyBaseReputationRegistry).updateOnConversionRejectedEvent(_converter, contractor, twoKeyAcquisitionCampaignERC20);
                c.state = ConversionState.REJECTED;
                conversions[conversionId] = c;
                reservedAmount += c.baseTokenUnits + c.bonusTokenUnits;
                refundAmount += c.conversionAmount;
            }
        }
        //If there's an amount to be returned and reserved tokens, update state and execute cashback
        if(reservedAmount > 0 && refundAmount > 0) {
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateReservedAmountOfTokensIfConversionRejectedOrExecuted(reservedAmount);
            ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).sendBackEthWhenConversionCancelled(_converter, refundAmount);
        }
    }

    /**
     * @notice Function to get all conversion ids for the converter
     * @param _converter is the address of the converter
     * @return array of conversion ids
     * @dev can only be called by converter itself or maintainer/contractor
     */
    function getConverterConversionIds(address _converter) external view returns (uint[]) {
//        require(msg.sender == contractor || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender) || msg.sender == _converter);
        return converterToHisConversions[_converter];
    }

    /**
     * @notice Function to get number of conversions
     * @dev Can only be called by contractor or maintainer
     */
    function getNumberOfConversions() external view returns (uint) {
        return numberOfConversions;
    }


    /**
     * @notice Function to cancel conversion and get back money
     * @param _conversionId is the id of the conversion
     * @dev returns all the funds to the converter back
     */
    function converterCancelConversion(uint _conversionId) external {
        Conversion memory conversion = conversions[_conversionId];
        require(conversion.conversionCreatedAt + 10*(1 days) < block.timestamp);
        require(msg.sender == conversion.converter);
        require(conversion.state == ConversionState.PENDING_APPROVAL);

        conversion.state = ConversionState.CANCELLED_BY_CONVERTER;
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).sendBackEthWhenConversionCancelled(msg.sender, conversion.conversionAmount);
        conversions[_conversionId] = conversion;
    }

    /**
     * @notice Get's number of converters per type, and returns tuple, as well as total raised funds
     getCampaignSummary
     */
    function getCampaignSummary() public view returns (uint,uint,uint,uint,uint,uint) {
        bytes32 pending = convertConverterStateToBytes(ConverterState.PENDING_APPROVAL);
        bytes32 approved = convertConverterStateToBytes(ConverterState.APPROVED);
        bytes32 rejected = convertConverterStateToBytes(ConverterState.REJECTED);

        uint numberOfPending = stateToConverter[pending].length;
        uint numberOfApproved = stateToConverter[approved].length;
        uint numberOfRejected = stateToConverter[rejected].length;

        return (numberOfPending,numberOfApproved,numberOfRejected,raisedFundsEthWei, tokensSold, totalBounty);
    }

    /**
     * @notice Fuunction where contractro/converter or mdoerator can see the lockup address for conversion
     * @param _conversionId is the id of conversion requested
     */
    function getLockupContractAddress(uint _conversionId) public view returns (address) {
        Conversion memory c = conversions[_conversionId];
        require(msg.sender == contractor || msg.sender == c.converter || ITwoKeyEventSource(twoKeyEventSource).isAddressMaintainer(msg.sender));
        return conversionId2LockupAddress[_conversionId];
    }

    /**
     * @notice Function to get converter state
     * @param _converter is the address of the requested converter
     * @return hexed string of the state
     */
    function getStateForConverter(address _converter) public view returns (bytes32) {
        return convertConverterStateToBytes(converterToState[_converter]);
    }

    /**
     * @notice Function to get number of executed functions
     * @return number of executed conversions on this contract
     */
    function getNumberOfExecutedConversions() public view returns (uint) {
        return numberOfExecutedConversions;
    }
}
