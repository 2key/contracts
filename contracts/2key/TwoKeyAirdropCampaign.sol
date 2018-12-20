pragma solidity ^0.4.24;

/**
 * @notice Contract for the airdrop campaigns
 * @author Nikola Madjarevic
 * Created at 12/20/18
 */
contract TwoKeyAirdropCampaign {

    // This will be the contract ERC20 from which we will do payouts
    address erc20ContractAddress;
    // Time when campaign starts
    uint campaignStartTime;
    // Time when campaign ends
    uint campaignEndTime;

    // Modifier which will prevent to do any actions if the time expired or didn't even started yet.
    modifier isOngoing {
        require(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime);
        _;
    }

    constructor() {

    }

}
