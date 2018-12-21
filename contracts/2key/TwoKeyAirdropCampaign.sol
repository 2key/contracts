pragma solidity ^0.4.24;

import "./TwoKeyConversionStates.sol";

/**
 * @notice Contract for the airdrop campaigns
 * @author Nikola Madjarevic
 * Created at 12/20/18
 */
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
    mapping(address => Conversion) converterToConversion;

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
    function convert() external onlyIfMaxNumberOfConversionsNotReached {

    }

    /**
     * @notice Function to approve conversion
     * @dev This function can be called only by contractor
     * @param conversionId is the id of the conversion (position in the array of conversions)
     */
    function approveConversion(uint conversionId) external onlyContractor {

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
}
