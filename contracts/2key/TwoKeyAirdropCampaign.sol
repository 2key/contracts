pragma solidity ^0.4.24;

/**
 * @notice Contract for the airdrop campaigns
 * @author Nikola Madjarevic
 * Created at 12/20/18
 */
contract TwoKeyAirdropCampaign {

    // This is representing the contractor (creator) of the campaign
    address contractor;
    // This is the amount of the tokens contractor is willing to spend for the airdrop campaign
    uint inventory;
    // This will be the contract ERC20 from which we will do payouts
    address erc20ContractAddress;
    // Time when campaign starts
    uint campaignStartTime;
    // Time when campaign ends
    uint campaignEndTime;
    // This is representing the total number of tokens which will be given as reward to the converter
    uint numberOfTokensPerConverter;
    // This is representing the total amount for the referral per conversion -> defaults to numberOfTokensPerConverter
    uint referralReward;

    // Modifier which will prevent to do any actions if the time expired or didn't even started yet.
    modifier isOngoing {
        require(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime);
        _;
    }


    //TODO: Expand and add modifiers to validate all the data is correct
    constructor(
        uint _inventory,
        address _erc20ContractAddress,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _numberOfTokensPerConverterAndReferralChain
    ) public {
        inventory = _inventory;
        erc20ContractAddress = _erc20ContractAddress;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        numberOfTokensPerConverter = _numberOfTokensPerConverterAndReferralChain;
        referralReward = _numberOfTokensPerConverterAndReferralChain;
    }

    /**
     * @notice Default payable function
     */
    function () payable external {

    }


}
