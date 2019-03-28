pragma solidity ^0.4.0;

import "./InvoiceTokenERC20.sol";
import "../TwoKeyConversionStates.sol";
import "../TwoKeyConverterStates.sol";

import "../libraries/SafeMath.sol";

import "../interfaces/ITwoKeyDonationCampaign.sol";

contract TwoKeyDonationConversionHandler is TwoKeyConversionStates, TwoKeyConverterStates {

    using SafeMath for uint; // Define lib necessary to handle uint operations

    address public twoKeyDonationCampaign;
    address public erc20InvoiceToken; // ERC20 token which will be issued as an invoice
    address contractor;

    uint maxReferralRewardPercent;
    uint [] counters; //Metrics counter

    mapping(address => ConverterState) converterToState; // Converter to state
    mapping(address => uint[]) converterToConversionIDs; // Converter to his conversion ids

    DonationEther[] donations;

    bool isKYCRequired;

    //Struct to represent donation in Ether
    struct DonationEther {
        address donator; //donator -> address who donated
        uint amount; //donation amount ETH
        uint contractorProceeds; // Amount which can be taken by contractor
        uint donationTimestamp; // When was donation created
        uint totalBountyEthWei; // Rewards amount in ether
        uint totalBounty2keyWei; // Rewards distributed between referrers for this campaign in 2key-tokens
        ConversionState state;
    }

    event InvoiceTokenCreated(
        address token,
        string tokenName,
        string tokenSymbol
    );

    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    constructor(
        string tokenName,
        string tokenSymbol
    ) public {
        contractor = msg.sender;
        // Deploy an ERC20 token which will be used as the Invoice
        erc20InvoiceToken = new InvoiceTokenERC20(tokenName,tokenSymbol,address(this));
        // Emit an event with deployed token address, name, and symbol
        emit InvoiceTokenCreated(erc20InvoiceToken, tokenName, tokenSymbol);
    }

    /**
     * @notice Function to initialize donation campaign, can be called only once
     * @param _twoKeyDonationCampaign is the address of twoKeyDonationCampaign
     * @param _isKYCRequired is the flag if KYC is required
     */
    function setTwoKeyDonationCampaign(
        address _twoKeyDonationCampaign,
        bool _isKYCRequired,
        uint _maxReferralRewardPercent
    ) public {
        require(twoKeyDonationCampaign == address(0));
        twoKeyDonationCampaign = _twoKeyDonationCampaign;
        isKYCRequired = _isKYCRequired;
        maxReferralRewardPercent = _maxReferralRewardPercent;
    }


    /**
     * @param _converter is the one who calls join and donate function
     * @param _donationAmount is the amount to be donated
     */
    function createDonation(address _converter, uint _donationAmount) public {
        //Basic accounting stuff
        // Calculate referrer rewards in ETH based on conversion amount
        uint referrerReward = (_donationAmount).mul(maxReferralRewardPercent).div(100 * (10**18));

        uint contractorProceeds = _donationAmount - referrerReward;

        // Create object for this donation
        DonationEther memory donation = DonationEther(_converter, _donationAmount, contractorProceeds, block.timestamp, referrerReward, 0, ConversionState.PENDING_APPROVAL);

        // Get donation ID
        uint id = donations.length;

        // Add donation id under donator id's
        converterToConversionIDs[_converter].push(id); // accounting for the donator

        // If KYC is not required or converter is approved conversion is automatically executed
        if(isKYCRequired == false || converterToState[_converter] == ConverterState.APPROVED) {
            // If there's a reward for influencers, distribute it between them
            if(referrerReward > 0) {
                uint totalBountyTokens = ITwoKeyDonationCampaign(twoKeyDonationCampaign).
                    distributeReferrerRewards(_converter, referrerReward, id);
                donation.totalBounty2keyWei = totalBountyTokens;
            }

            // Function to update contractor balance and user contribution once conversion is executed
            ITwoKeyDonationCampaign(twoKeyDonationCampaign).updateContractorBalanceAndConverterDonations(
                _converter,
                donation.contractorProceeds,
                _donationAmount
            );
            // Update the state of donation
            donation.state = ConversionState.EXECUTED;
            // Add donation to array of all donations
            donations.push(donation);
            // Transfer invoice token to donator (Contributor)
            InvoiceTokenERC20(erc20InvoiceToken).transfer(_converter, _donationAmount);
            // Update that donator is approved (since KYC is false every donator will be approved)
            converterToState[_converter] = ConverterState.APPROVED;
        } else {

            if(converterToState[_converter] == ConverterState.REJECTED) {
                revert();
            }

            if(converterToState[_converter] == ConverterState.NOT_EXISTING) {
                // Handle converter to wait for approval
                converterToState[_converter] = ConverterState.PENDING_APPROVAL;

                // Add donation to array of all donations
                donations.push(donation);
            }
        }
    }

    function approveConverter(address _converter) public onlyContractor {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);

        uint[] memory conversionIds = converterToConversionIDs[_converter];
        uint totalContractorProceeds = 0;
        uint totalConverterDonations = 0;

        for(uint i=0; i<conversionIds.length; i++) {
            DonationEther storage don = donations[conversionIds[i]];

            if(don.state == ConversionState.PENDING_APPROVAL) {
                totalContractorProceeds = totalContractorProceeds.add(don.contractorProceeds);
                totalConverterDonations = totalConverterDonations.add(don.amount);
                // Distribute rewards between referrers once campaign is executed
                don.totalBounty2keyWei = ITwoKeyDonationCampaign(twoKeyDonationCampaign).
                    distributeReferrerRewards(_converter, don.totalBountyEthWei, conversionIds[i]);
                // Change donation state to be executed
                don.state = ConversionState.EXECUTED;
            }
        }

        if(totalConverterDonations > 0 && totalContractorProceeds > 0) {
            // Update state after converter is approved since all his donations will be executed
            ITwoKeyDonationCampaign(twoKeyDonationCampaign).updateContractorBalanceAndConverterDonations(
                _converter,
                totalContractorProceeds,
                totalConverterDonations
            );
        }

        // Change converter state to approved
        converterToState[_converter] = ConverterState.APPROVED;
    }

    /**
     * @notice Function to read donation
     * @param donationId is the id of donation
     */
    function getDonation(uint donationId) public view returns (bytes) {
        DonationEther memory donation = donations[donationId];

        return abi.encodePacked(
            donation.donator,
            donation.amount,
            donation.contractorProceeds,
            donation.donationTimestamp,
            donation.totalBountyEthWei,
            donation.totalBounty2keyWei,
            donation.state
        );
    }
}
