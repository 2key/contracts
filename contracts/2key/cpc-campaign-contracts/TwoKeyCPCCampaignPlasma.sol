pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyPlasmaCampaign.sol";
import "../libraries/MerkleProof.sol";
import "../libraries/IncentiveModels.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";


contract TwoKeyCPCCampaignPlasma is UpgradeableCampaign, TwoKeyPlasmaCampaign {

    uint totalBountyForCampaign; //total 2key tokens amount staked for the campaign
    uint bountyPerConversion; //amount of 2key tokens which are going to be paid per conversion

    IncentiveModel model;

    string public targetUrl;
    address public mirrorCampaignOnPublic; // Address of campaign deployed to public eth network

    address[] public activeInfluencers;

    mapping(address => bool) isConverter;
    mapping(address => uint) activeInfluencer2idx;

    bytes32 public merkle_root;
    bytes32[] public merkle_roots;


    struct Conversion {
        address converterPlasma;
        uint bountyPaid;
        uint conversionTimestamp;
    }

    //TODO: This event should be removed, unnecessary spending gas especially since it's called in a loop. Consider with Udi
    event ConvertSig(
        address influencer,
        bytes signature,
        address plasmaConverter,
        address functionCaller // can be either contractor or maintainer
    );


    function setInitialParamsCPCCampaignPlasma(
        address _twoKeyPlasmaSingletonRegistry,
        address _contractor,
        address _moderator,
        string _url,
        uint [] numberValues
    )
    public
    {
        require(isCampaignInitialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        contractor = _contractor;
        moderator = _moderator;
        targetUrl = _url; // Set the contractor of the campaign

        campaignStartTime = numberValues[0];
        campaignEndTime = numberValues[1];
        maxReferralRewardPercent = numberValues[2];
        conversionQuota = numberValues[3];
        totalSupply_ = numberValues[4];
        incentiveModel = IncentiveModel(numberValues[5]);

        received_from[_contractor] = _contractor;
        balances[_contractor] = totalSupply_;

        isCampaignInitialized = true;
    }

    /**
     * @notice Function to validate that contracts plasma and public are well mirrored
     */
    function validateContractFromMaintainer()
    public
    onlyMaintainer
    {
        isValidated = true;
    }

    /**
     * @notice Will be called only once in a lifetime, immediately after campaign on public network is deployed
     * @param _mirrorCampaign is the campaign address on public network
     */
    function setMirrorCampaign(
        address _mirrorCampaign
    )
    public
    onlyContractor
    {
        require(mirrorCampaignOnPublic == address(0));
        mirrorCampaignOnPublic = _mirrorCampaign;
    }

    /**
     * @notice Function where maintainer will set on plasma network the total bounty amount
     * and how many tokens are paid per conversion for the influencers
     */
    function setTotalBounty(
        uint _totalBounty,
        uint _bountyPerConversion
    )
    public
    onlyMaintainer
    {
        // So if contractor adds more bounty we can increase it
        totalBountyForCampaign = totalBountyForCampaign.add(_totalBounty);
        if(bountyPerConversion == 0) {
            // Bounty per conversion can't be changed
            bountyPerConversion = _bountyPerConversion;
        }

    }

    /**
     * @notice Function to return referrers participated in the referral chain
     * @param customer is the one who converted
     * @return array of referrer addresses
     */
    function getReferrers(
        address customer
    )
    public
    view
    returns (address[])
    {
        address influencer = customer;
        uint n_influencers = 0;

        while (true) {
            influencer = getReceivedFrom(influencer);
            if (influencer == contractor) {
                break;
            }
            n_influencers = n_influencers.add(1);
        }
        address[] memory influencers = new address[](n_influencers);
        influencer = customer;

        while (n_influencers > 0) {
            influencer = getReceivedFrom(influencer);
            n_influencers = n_influencers.sub(1);
            influencers[n_influencers] = influencer;
        }
        return influencers;
    }

    /**
     * @notice Function where converter can convert
     */
    function convert(
        bytes signature,
        address converter
    )
    private
    {
        require(isConverter[converter] == false); // Requiring that user can convert only 1 time
        isConverter[converter] = true;

        if(received_from[converter] == address(0)) {
            distributeArcsBasedOnSignature(signature, converter);
        }
    }


    function convertByMaintainerSig(
        bytes signature,
        bytes converterSig
    )
    public
    onlyContractorOrMaintainer
    {
        require(merkle_root == 0, 'merkle root already defined, contract is locked');

        address plasmaConverter = Call.recoverHash(keccak256(signature), converterSig, 0);

        convert(signature, plasmaConverter);

        address[] memory influencers = getReferrers(plasmaConverter);

        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers-1; i++) {
            emit ConvertSig(influencers[i], signature, plasmaConverter, msg.sender);
        }
    }

    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[_referrer];
    }

    /**
     * @notice Function to update referrer plasma balance
     * @param _influencer is the plasma address of referrer
     * @param _balance is the new balance
     */
    function updateReferrerPlasmaBalance(
        address _influencer,
        uint _balance
    )
    public
    {
//        require(msg.sender == twoKeyDonationLogicHandler);
        if (activeInfluencer2idx[_influencer] == 0) {
            activeInfluencers.push(_influencer);
            activeInfluencer2idx[_influencer] = activeInfluencers.length;
        }
        referrerPlasma2Balances2key[_influencer] = referrerPlasma2Balances2key[_influencer].add(_balance);
    }

    function resetMerkleRoot()
    public
    onlyMaintainer
    {
        // TODO this needs to be blocked or only used when using Epoches
        merkle_root = bytes32(0);
        if (merkle_roots.length > 0) {
            delete merkle_roots;
        }
    }

    /**
     * @notice set a merkle root of the amount each (active) influencer received.
     *         (active influencer is an influencer that received a bounty)
     *         the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     */
    function setMerkleRoot(
        bytes32 _merkle_root
    )
    public
    onlyMaintainer
    {
        require(merkle_root == 0, 'merkle root already defined');
        merkle_root = _merkle_root;
    }


    function computeMerkleRoot(
    )
    public
    onlyMaintainer
    {
        require(merkle_root == 0, 'merkle root already defined');

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            // lock the contract without any influencer
            merkle_root = bytes32(1);
            return;
        }

        bytes32[] memory hashes = new bytes32[](numberOfInfluencers);
        uint i;
        for (i = 0; i < numberOfInfluencers; i++) {
            address influencer = activeInfluencers[i];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }
        merkle_root = MerkleProof.computeMerkleRootInternal(hashes);
    }


    /**
     * @notice compute a merkle root of the active influencers and the amount they received.
     *         (active influencer is an influencer that received a bounty)
     *         this function needs to be called many times until merkle_root is not 2.
     *         In each call a merkle tree of up to N leaves (pair of active-influencer and amount) is
     *         computed and the result is added to merkle_roots. N should be a power of 2 for example N=2048.
     *         On all calls you have to use the same N value.
     *         Once you the leaves are computed you need to call this function one more time to compute the
     *         merkle_root of the entire tree from the intermidate results in merkle_roots
     */
    function computeMerkleRoots(
        uint N // maximnal number of leafs we are going to process in each call. for example 2**11
    )
    public
    onlyMaintainer
    {
        require(merkle_root == 0 || merkle_root == 2, 'merkle root already defined');

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            merkle_root = bytes32(1);
            return;
        }
        merkle_root = bytes32(2); // indicate that the merkle root is being computed

        uint start = merkle_roots.length * N;
        if (start >= numberOfInfluencers) {
            merkle_root = MerkleProof.computeMerkleRootInternal(merkle_roots);
            return;
        }

        uint n = numberOfInfluencers - start;
        if (n > N) {
            n = N;
        }
        bytes32[] memory hashes = new bytes32[](n);
        for (uint i = 0; i < n; i++) {
            address influencer = activeInfluencers[i+start];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }
        merkle_roots.push(MerkleProof.computeMerkleRootInternal(hashes));
    }

    function executeConversion(uint conversionID) public onlyMaintainer {

    }


}
