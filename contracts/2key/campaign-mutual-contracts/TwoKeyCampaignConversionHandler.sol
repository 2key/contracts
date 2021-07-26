pragma solidity ^0.4.24;

import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyCampaignLogicHandler.sol";

contract TwoKeyCampaignConversionHandler is TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint256;

    uint expiryConversionInHours; // How long converter can be pending before he can cancel his conversion

    event ConversionCreated(uint conversionId);

    bool isCampaignInitialized;
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
     * counters[10] = CAMPAIGN_RAISED_BY_NOW_IN_CAMPAIGN_CURRENCY
     */
    uint [] counters;

    address contractor;
    address twoKeyEventSource;
    address twoKeyBaseReputationRegistry;
    address twoKeySingletonRegistry;


    mapping(address => uint256) amountConverterSpentEthWEI; // Amount converter put to the contract in Ether
    mapping(bytes32 => address[]) stateToConverter; //State to all converters in that state
    mapping(address => uint[]) converterToHisConversions;
    mapping(address => ConverterState) converterToState; //Converter to his state
    mapping(address => uint256) public converterToPositionIndex;
    mapping(address => bool) isConverterAnonymous;
    mapping(address => bool) doesConverterHaveExecutedConversions;
    mapping(uint => uint) conversionToCampaignCurrencyAmountAtTimeOfCreation;

    modifier onlyContractorOrMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(msg.sender == contractor || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }


    // Internal function to fetch address from TwoKeySingletonRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry)
        .getContractProxyAddress(contractName);
    }

    /**
     * given the total payout, calculates the moderator fee
     * @param  _conversionAmountETHWei total payout for escrow
     * @return moderator fee
     */
    function calculateModeratorFee(
        uint256 _conversionAmountETHWei
    )
    internal
    view
    returns (uint256)
    {
        uint256 fee = _conversionAmountETHWei.mul(ITwoKeyEventSource(twoKeyEventSource).getTwoKeyDefaultIntegratorFeeFromAdmin()).div(100);
        return fee;
    }


    function getAllConvertersPerState(
        bytes32 state
    )
    public
    view
    returns (address[])
    {
        return stateToConverter[state];
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
        address[] memory current = stateToConverter[key];

        uint index = converterToPositionIndex[_converter]; // Get converter index position in array
        if(current[index] == _converter) {
            // Add converter to new array
            stateToConverter[destinationState].push(_converter);
            // Set new position in the new array
            converterToPositionIndex[_converter] = stateToConverter[destinationState].length - 1;
            // Get the last converter from the array because we're moving him to deleted place and with that action
            // His new index will be the one of the removed converter
            address lastConverterInArray = current[current.length-1];
            // Reduce size of current array
            current[index] = lastConverterInArray;
            // Set index to be the position of the last converter in the array
            converterToPositionIndex[lastConverterInArray] = index;
            // Delete last element in current array
            delete current[current.length-1];
            // Save current array
            stateToConverter[key] = current;
            // Change length of the mapping array
            stateToConverter[key].length = stateToConverter[key].length.sub(1);
        }
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
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingOrRejectedToApprovedState(_converter);
    }

    function rejectConverterInternal(
        address _converter
    )
    internal
    {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingToRejectedState(_converter);
    }

    function handleConverterState(
        address _converterAddress,
        bool isKYCRequired
    )
    internal
    {
        //If KYC is required, basic funnel executes and we require that converter is not previously rejected
        if(isKYCRequired == true) {
            require(converterToState[_converterAddress] != ConverterState.REJECTED); // If converter is rejected then can't create conversion
            // Checking the state for converter, if this is his 1st time, he goes initially to PENDING_APPROVAL
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
                stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
                converterToPositionIndex[_converterAddress] = stateToConverter[bytes32("PENDING_APPROVAL")].length-1;
            }
        } else {
            //If KYC is not required converter is automatically approved
            if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
                converterToState[_converterAddress] = ConverterState.APPROVED;
                stateToConverter[bytes32("APPROVED")].push(_converterAddress);
                converterToPositionIndex[_converterAddress] = stateToConverter[bytes32("APPROVED")].length-1;
            }
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

    /**
     * @notice Get's number of converters per type, and returns tuple, as well as total raised funds
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



}
