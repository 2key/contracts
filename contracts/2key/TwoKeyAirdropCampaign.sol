pragma solidity ^0.4.24;

import "./TwoKeyConversionStates.sol";

/**
 * @notice Contract for the airdrop campaigns
 * @author Nikola Madjarevic
 * Created at 12/20/18
 */
//TODO: Inherit arc contract
//TODO: See the best pattern to apply for storing converter balance (maybe mapping or simple array of converters)
contract TwoKeyAirdropCampaign is TwoKeyConversionStates {

    // This is representing the contractor (creator) of the campaign
    address contractor;
    // This is the amount of the tokens contractor is willing to spend for the airdrop campaign
    uint inventoryAmount;
    // This will be the contract ERC20 from which we will do payouts
    address erc20ContractAddress;
    // Time when campaign starts
    uint campaignStartTime;
    // Time when campaign ends
    uint campaignEndTime;
    // This is representing the total number of tokens which will be given as reward to the converter
    uint public numberOfTokensPerConverter;
    // This is representing the total amount for the referral per conversion -> defaults to numberOfTokensPerConverter
    uint referralReward;
    // Array of conversion objects
    Conversion[] conversions;
    // Number of conversions - representing at the same time conversion id
    uint numberOfConversions = 0;
    // Regarding fixed inventory and reward per conversion there is total number of conversions per campaign
    uint maxNumberOfConversions;
    // Mapping converter address to the conversion => There can be only 1 converter per conversion
    mapping(address => uint) converterToConversionId;
    // Mapping referrer address to his balance
    mapping(address => uint) referrerBalancesEthWEI;
    // Mapping referrer address to his total earnings (only used for the statistics)
    mapping(address => uint) referrerTotalEarningsEthWEI;
    // Mapping which will follow if converter has withdrawn his earnings
    mapping(address => bool) hasConverterWithdrawnHisEarnings;


    struct Conversion {
        address converter;
        uint conversionTime; //We can add this optional thing, like saving timestamp when conversion is created
        ConversionState state;
    }

    // Modifier which will prevent to do any actions if the time expired or didn't even started yet.
    modifier isOngoing {
        require(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime);
        _;
    }

    // Modifier which will restrict to overflow number of conversions
    modifier onlyIfMaxNumberOfConversionsNotReached {
        require(numberOfConversions < maxNumberOfConversions);
        _;
    }

    // Modifier which will prevent to do any actions if the msg.sender is not the contractor
    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    constructor(
        uint _inventory,
        address _erc20ContractAddress,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _numberOfTokensPerConverterAndReferralChain
    ) public {
        contractor = msg.sender;
        inventoryAmount = _inventory;
        erc20ContractAddress = _erc20ContractAddress;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        numberOfTokensPerConverter = _numberOfTokensPerConverterAndReferralChain;
        referralReward = _numberOfTokensPerConverterAndReferralChain;
        maxNumberOfConversions = inventoryAmount / (2*_numberOfTokensPerConverterAndReferralChain);
    }

    /**
     * @notice Default payable function
     */
    function () payable external {

    }

    /**
     * @notice Function which will be executed to create conversion
     * @dev This function will revert if the maxNumberOfConversions is reached
     */
    function convert(bytes signature) external onlyIfMaxNumberOfConversionsNotReached {
        //TODO: Add validators, update rewards fields, parse signature, etc.

        Conversion memory c = Conversion({
            converter: msg.sender,
            conversionTime: block.timestamp,
            state: ConversionState.PENDING_APPROVAL
        });
        conversions.push(c);
        numberOfConversions++;
    }

    /**
     * @notice Function to approve conversion
     * @dev This function can be called only by contractor
     * @param conversionId is the id of the conversion (position in the array of conversions)
     */
    function approveConversion(uint conversionId) external onlyContractor {
        Conversion memory c = conversions[conversionId];
        if(c.state == ConversionState.PENDING_APPROVAL) {
            c.state = ConversionState.APPROVED;
        }
        conversions[conversionId] = c;
    }

    /**
     * @notice Function to reject conversion
     * @dev This function can be called only by contractor
     * @param conversionId is the id of the conversion
     */
    function rejectConversion(uint conversionId) external onlyContractor {
        Conversion memory c = conversions[conversionId];
        if(c.state == ConversionState.PENDING_APPROVAL) {
            c.state = ConversionState.REJECTED;
        }
        conversions[conversionId] = c;
    }

    /**
     * @notice Function to return dynamic and static contract data, visible to everyone
     * @return encoded data
     */
    function getContractInformations() external view returns (bytes) {
        return abi.encodePacked(
            contractor,
            inventoryAmount,
            erc20ContractAddress,
            campaignStartTime,
            campaignEndTime,
            numberOfTokensPerConverter,
            numberOfConversions,
            maxNumberOfConversions
        );
    }

    /**
     * @notice Function returns the total available balance of the referrer and his total earnings for this campaign
     * @dev only referrer by himself or contractor can see the balance of the referrer
     * @param _referrer is the address of the referrer we're checking balance for
     */
    function getReferrerBalanceAndTotalEarnings(address _referrer) external view returns (uint,uint){
        require(msg.sender == contractor || msg.sender == _referrer);
        return (referrerBalancesEthWEI[_referrer], referrerTotalEarningsEthWEI[_referrer]);
    }

    /**
     * @notice Function to get conversion object
     * @param conversionId is the id of the conversion
     * @return tuple containing respectively converter address, conversionTime, and state of the conversion
     */
    function getConversion(uint conversionId) external view returns (address, uint, bytes32) {
        Conversion memory conversion = conversions[conversionId];
        require(msg.sender == conversion.converter || msg.sender == contractor);
        return (conversion.converter, conversion.conversionTime, convertConversionStateToBytes(conversion.state));
    }

    function converterWithdraw() external view {
        uint conversionId = converterToConversionId[msg.sender];
        Conversion memory c = conversions[conversionId];
        require(c.state == ConversionState.APPROVED);
        hasConverterWithdrawnHisEarnings[msg.sender] = true;
//        msg.sender.transfer(numberOfTokensPerConverter); this is going to be an erc20 transfer
        c.state = ConversionState.EXECUTED;
        conversions[conversionId] = c;
    }
}
