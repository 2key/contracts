pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyPlasmaCampaign.sol";

contract TwoKeyCPCCampaignPlasma is TwoKeyPlasmaCampaign {


    address public mirrorCampaignOnPublic; // Address of campaign deployed to public eth network
    address[] public activeInfluencers;

    mapping(address => bool) isConverter;
    mapping(address => uint) activeInfluencer2idx;

    bytes32 public merkle_root;
    bytes32[] public merkle_roots;

    string public target_url;


    event ConvertSig(
        address indexed influencer,
        bytes signature,
        address plasmaConverter,
        bytes maintainerSig
    );


    function setInitialParamsCPCCampaign(
        address _moderator,
        string _url
    )
    public
    {
        require(isCampaignInitialized == false);

        // Set the contractor of the campaign
        contractor = msg.sender;
        moderator = _moderator;

        target_url = _url;

        isCampaignInitialized = true;
    }

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
     * @notice Function to return referrers participated in the referral chain
     * @param customer is the one who converted (bought tokens)
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
        bytes converterSig,
        bytes maintainerSig
    )
    public
    {
        require(merkle_root == 0, 'merkle root already defined, contract is locked');

        address plasmaConverter = Call.recoverHash(keccak256(signature), converterSig, 0);
        address m = Call.recoverHash(keccak256(abi.encodePacked(signature,converterSig)), maintainerSig, 0);
        require(moderator == m);

        convert(signature, plasmaConverter); // msg.value  contract donates 1ETH

        address[] memory influencers = getReferrers(plasmaConverter);

        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers-1; i++) {
            emit ConvertSig(influencers[i], signature, plasmaConverter, maintainerSig);
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
//    onlyModerator
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
//    onlyModerator
    {
        require(merkle_root == 0, 'merkle root already defined');
        merkle_root = _merkle_root;
    }


    function computeMerkleRootInternal(
        bytes32[] hashes
    )
    internal
    returns (bytes32)
    {
        uint n = hashes.length;
        while (n>1) {
            for (uint i = 0; i < n; i+=2) {
                bytes32 h0 = hashes[i];
                bytes32 h1;
                if (i+1 < n) {
                    h1 = hashes[i+1];
                }
                if (h0 < h1) {
                    hashes[i>>1] = keccak256(abi.encodePacked(h0,h1));
                } else {
                    hashes[i>>1] = keccak256(abi.encodePacked(h1,h0));
                }
            }
            if ((n & (n - 1)) != 0) {
                n >>= 1;
                n++;
            } else {
                n >>= 1;
            }
        }
        return hashes[0];
    }

    function computeMerkleRoot(
    )
    public
//    onlyModerator
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
        merkle_root = computeMerkleRootInternal(hashes);
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
//    onlyModerator
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
            merkle_root = computeMerkleRootInternal(merkle_roots);
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
        merkle_roots.push(computeMerkleRootInternal(hashes));
    }







}
