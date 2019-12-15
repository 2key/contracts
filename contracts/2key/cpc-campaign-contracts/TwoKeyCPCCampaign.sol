pragma solidity ^0.4.24;

import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../libraries/MerkleProof.sol";
import "./TwoKeyBudgetCampaign.sol";
/**
 * @author Nikola Madjarevic
 * @author Ehud Ben-Reuven
 * Date added : 1st December 2019
 */
contract TwoKeyCPCCampaign is UpgradeableCampaign, TwoKeyBudgetCampaign {

    bytes32 public merkleRoot;
    string public targetUrl;
    address public mirrorCampaignOnPlasma; // Address of campaign deployed to plasma network

    bool public isValidated;

    /**
     * @notice Function to validate that contracts plasma and public are well mirrored
     */
    function validateContractFromMaintainer()
    public
    onlyMaintainer
    {
        isValidated = true;
    }


    function setInitialParamsCPCCampaign(
        address _contractor,
        address _twoKeySingletonRegistry,
        string _url,
        address _mirrorCampaignOnPlasma,
        uint _bountyPerConversion
    )
    public
    {
        require(isCampaignInitialized == false);

        // Set the contractor of the campaign
        contractor = _contractor;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));

        // Set the moderator of the campaign
        moderator = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Set target url to be visited
        targetUrl = _url;

        // Set bounty per conversion
        bountyPerConversion = _bountyPerConversion;

        //Set mirror campaign on plasma
        mirrorCampaignOnPlasma = _mirrorCampaignOnPlasma;

        isCampaignInitialized = true;
    }

    /**
     * @notice validate a merkle proof.
     */
    function checkMerkleProof(
        address influencer,
        bytes32[] proof,
        uint amount
    )
    public
    view
    returns (bool)
    {
        if(merkleRoot == 0) // merkle root was not yet set by contractor
            return false;
        return MerkleProof.verifyProof(proof,merkleRoot,keccak256(abi.encodePacked(influencer,amount)));
    }

    /**
     * @notice set a merkle root of the amount each (active) influencer received.
     *         (active influencer is an influencer that received a bounty)
     *         the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     */
    function setMerkleRoot(
        bytes32 _merkleRoot
    )
    public
    onlyMaintainer
    {
        require(merkleRoot == 0, 'merkle root already defined');
        merkleRoot = _merkleRoot;
    }

    function getPlasmaOf(address _a)
    internal
    view
    returns (address)
    {
        return twoKeyEventSource.plasmaOf(_a);
    }

    function submitProofAndWithdrawRewards(
        bytes32 [] proof,
        uint amount
    )
    public
    {
        address influencerPlasma = twoKeyEventSource.plasmaOf(msg.sender);

        //Validating that this is the amount he earned
        require(checkMerkleProof(influencerPlasma,proof,amount), 'proof is invalid');

        //Assuming that msg.sender is influencer
        require(areRewardsWithdrawn[msg.sender] == false); //He can't take reward twice

        //Sending him his rewards
        transferERC20(msg.sender, amount);

        //Incrementing amount he has earned
        amountInfluencerEarned[msg.sender] = amount;
    }

}
