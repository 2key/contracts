pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyBudgetCampaign.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";

/**
 * @author Nikola Madjarevic
 * @author Ehud Ben-Reuven
 * Date added : 1st December 2019
 */
contract TwoKeyCPCCampaign is UpgradeableCampaign, TwoKeyBudgetCampaign {

    address[] public activeInfluencers;
    mapping(address => uint) activeInfluencer2Index;
    bytes32 public merkleRoot;
    bytes32[] public merkleRoots;
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
        address _moderator,
        address _twoKeySingletonRegistry,
        string _url,
        address _mirrorCampaignOnPlasma
    )
    public
    {
        require(isCampaignInitialized == false);

        // Set the contractor of the campaign
        contractor = msg.sender;
        moderator = _moderator;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        targetUrl = _url;
        mirrorCampaignOnPlasma = _mirrorCampaignOnPlasma;

        isCampaignInitialized = true;
    }

    function submitProofAndWithdrawRewards(bytes32 proof) public {

    }

}
