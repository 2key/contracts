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
    mapping(address => uint) activeInfluencer2idx;
    bytes32 public merkle_root;  // merkle root of the entire tree OR 0 - undefined, 1 - tree is empty, 2 - being computed, call computeMerkleRoots again
    // merkle tree with 2K or more leaves takes too much gas so we need to break the influencers into buckets of size <=2K
    // and compute merkle root for each bucket by calling computeMerkleRoots many times
    bytes32[] public merkle_roots;
    string public target_url;
    address public mirrorCampaignOnPlasma; // Address of campaign deployed to plasma network


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

        twoKeySingletonesRegistry = _twoKeySingletonRegistry;

        target_url = _url;
        mirrorCampaignOnPlasma = _mirrorCampaignOnPlasma;

        isCampaignInitialized = true;
    }


}
