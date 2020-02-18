pragma solidity ^0.4.24;

import "../libraries/MerkleProof.sol";
import "../libraries/IncentiveModels.sol";
import "../libraries/Call.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../TwoKeyConversionStates.sol";
import "./TwoKeyPlasmaCampaign.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";


contract TwoKeyCPCCampaignPlasma is UpgradeableCampaign, TwoKeyPlasmaCampaign, TwoKeyConversionStates {


    uint totalBountyForCampaign; //total 2key tokens amount staked for the campaign
    uint bountyPerConversionWei; //amount of 2key tokens which are going to be paid per conversion

    uint public maxNumberOfConversions; // maximal number of conversions campaign can support

    event ConversionCreated(uint conversionId);

    /**
     0 pendingConverters
     1 approvedConverters
     2 rejectedConverters
     3 pendingConversions
     4 rejectedConversions
     5 executedConversions
     6 totalBounty
     */
    uint [] counters;

    uint constant public N = 2048; //constant number

    // Incentive model selected for campaign
    IncentiveModel model;

    // Url being tracked
    string public targetUrl;

    // Address of campaign deployed to public eth network
    address public mirrorCampaignOnPublic;

    //Active influencer means that he has at least on participation in successful conversion
    address[] activeInfluencers;

    // Mapping active influencers
    mapping(address => bool) isActiveInfluencer;
    mapping(address => uint) activeInfluencer2idx;

    mapping(address => bool) public isConverter;
    mapping(address => bool) isApprovedConverter;

    mapping(address => bytes) converterToSignature;

    bytes32 public merkleRoot;
    bytes32[] merkle_roots;


    struct Conversion {
        address converterPlasma;
        uint bountyPaid;
        uint conversionTimestamp;
        ConversionState state;
    }

    Conversion [] conversions;

    mapping(address => uint) public converterToConversionId;

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
        contractorPublicAddress = ethereumOf(_contractor);
        campaignStartTime = numberValues[0];
        campaignEndTime = numberValues[1];
        conversionQuota = numberValues[2];
        totalSupply_ = numberValues[3];
        incentiveModel = IncentiveModel(numberValues[4]);
        bountyPerConversionWei = numberValues[5];
        received_from[_contractor] = _contractor;
        balances[_contractor] = totalSupply_;

        counters = new uint[](8);
        isCampaignInitialized = true;
    }


    modifier contractNotLocked {
        require(merkleRoot == 0);
        _;
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
        uint _totalBounty
    )
    public
    onlyMaintainer
    {
        // So if contractor adds more bounty we can increase it
        totalBountyForCampaign = totalBountyForCampaign.add(_totalBounty);
        maxNumberOfConversions = totalBountyForCampaign.div(bountyPerConversionWei);
    }


    /**
     * @notice Function to get total bounty available and bounty per conversion
     * @return tuple
     */
    function getTotalBountyAndBountyPerConversion()
    public
    view
    returns (uint,uint)
    {
        return (totalBountyForCampaign, bountyPerConversionWei);
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
        uint numberOfInfluencers = converterToNumberOfInfluencers[customer];

        address[] memory influencers = new address[](numberOfInfluencers);


        while (numberOfInfluencers > 0) {
            influencer = getReceivedFrom(influencer);
            numberOfInfluencers--;
            influencers[numberOfInfluencers] = influencer;
        }
        return influencers;
    }



    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(
        address _referrerAddress,
        bytes _sig,
        uint[] _conversionIds
    )
    public
    view
    returns (uint,uint,uint,uint[],address)
    {

        if(_sig.length > 0) {
            _referrerAddress = recover(_sig);
        }
        else {
            _referrerAddress = _referrerAddress;
        }

        uint len = _conversionIds.length;
        uint[] memory earnings = new uint[](len);

        for(uint i=0; i<len; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrerAddress][_conversionIds[i]];
        }

        uint referrerBalance = referrerPlasma2Balances2key[_referrerAddress];
        return (referrerBalance, referrerPlasma2TotalEarnings2key[_referrerAddress], referrerPlasmaAddressToCounterOfConversions[_referrerAddress], earnings, _referrerAddress);
    }

    /**
     * @notice Internal helper function
     */
    function recover(
        bytes signature
    )
    internal
    view
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
            keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
        return Call.recoverHash(hash, signature, 0);
    }




    function convert(
        bytes signature
    )
    contractNotLocked
    isCampaignValidated
    public
    {
        require(merkleRoot == 0);

        require(isConverter[msg.sender] == false); // Requiring that user can convert only 1 time
        isConverter[msg.sender] = true;

        // Save converter signature on the blockchain
        converterToSignature[msg.sender] = signature;

        // Create conversion
        Conversion memory c = Conversion (
            msg.sender,
            0,
            block.timestamp,
            ConversionState.PENDING_APPROVAL
        );

        // Get the ID and update mappings
        uint conversionId = conversions.length;
        conversions.push(c);
        converterToConversionId[msg.sender] = conversionId;
        counters[0]++; //Increase number of pending converters and conversions
        counters[3]++; //Increase number of pending conversions

        //Emit conversion event through TwoKeyPlasmaEvents
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitConversionCreatedEvent(
            mirrorCampaignOnPublic,
            conversionId,
            contractor,
            msg.sender
        );
    }

    /**
     * @notice Internal function to make converter approved if it's his 1st conversion
     * @param _converter is the plasma address of the converter
     */
    function oneTimeApproveConverter(
        address _converter
    )
    internal
    {
        require(isApprovedConverter[_converter] == false);
        isApprovedConverter[_converter] = true;
    }


    /**
     * @notice Function to approve converter and execute conversion, can be called once per converter
     * @param converter is the plasma address of the converter
     */
    function approveConverterAndExecuteConversion(
        address converter
    )
    public
    contractNotLocked
    onlyMaintainer
    isCampaignValidated
    {
        //Check if converter don't have any executed conversions before and approve him
        oneTimeApproveConverter(converter);

        // Get the converter signature
        bytes memory signature = converterToSignature[converter];
        // Distribute arcs if necessary
        distributeArcsIfNecessary(converter, signature);
        //Get the conversion id
        uint conversionId = converterToConversionId[converter];
        // Get the conversion object
        Conversion storage c = conversions[conversionId];
        // Update state of conversion to EXECUTED
        c.state = ConversionState.EXECUTED;

        // If the conversion is not directly from the contractor and there's enough rewards for this conversion we will distribute them
        if(converterToNumberOfInfluencers[converter] > 0 && counters[6].add(bountyPerConversionWei) <= totalBountyForCampaign) {
            //Get moderator fee percentage
            uint moderatorFeePercent = getModeratorFeePercent();
            //Calculate moderator fee to be taken from bounty
            uint moderatorFee = bountyPerConversionWei.mul(moderatorFeePercent).div(100);
            //Add earnings to moderator total earnings
            moderatorTotalEarnings = moderatorTotalEarnings.add(moderatorFee);
            //Left to be distributed between influencers
            uint bountyToBeDistributed = bountyPerConversionWei.sub(moderatorFee);

            //Distribute rewards between referrers
            updateRewardsBetweenInfluencers(converter, conversionId, bountyToBeDistributed);
            //Update paid bounty
            c.bountyPaid = bountyToBeDistributed;
            //Increment how much bounty is paid
            counters[6] = counters[6] + bountyToBeDistributed; // Total bounty paid
        }

        counters[0]--; //Decrement number of pending conversions
        //Increment number of executed conversions
        counters[1]++; //increment number approved converters
        counters[5]++; //increment number of executed conversions

        //Emit event through TwoKeyEventSource that conversion is approved and executed
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource")).emitConversionExecutedEvent(
            conversionId
        );
    }


    function rejectConverterAndConversion(
        address converter
    )
    public
    contractNotLocked
    onlyMaintainer
    isCampaignValidated
    {
        require(isApprovedConverter[converter] == false);

        // Get the conversion ID
        uint conversionId = converterToConversionId[converter];

        // Get the conversion object
        Conversion storage c = conversions[conversionId];

        require(c.state == ConversionState.PENDING_APPROVAL);
        c.state = ConversionState.REJECTED;

        counters[0]--; //reduce number of pending converters
        counters[2]++; //increase number of rejected converters
        counters[3]--; //reduce number of pending conversions
        counters[4]++; //increase number of rejected conversions
    }

    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[_referrer];
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
    function computeMerkleRoots()
    public
    onlyMaintainer
    {
        require(merkleRoot == 0 || merkleRoot == 2, 'merkle root already defined');

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            merkleRoot = bytes32(1);
            return;
        }
        merkleRoot = bytes32(2); // indicate that the merkle root is being computed

        uint start = merkle_roots.length * N;
        if (start >= numberOfInfluencers) {
            merkleRoot = MerkleProof.computeMerkleRootInternal(merkle_roots);
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


    function checkIsActiveInfluencerAndAddToQueue(
        address _influencer
    )
    internal
    {
        if(!isActiveInfluencer[_influencer]) {
            activeInfluencer2idx[_influencer] = activeInfluencers.length;
            activeInfluencers.push(_influencer);
            isActiveInfluencer[_influencer] = true;
        }
    }

    function getConversion(
        uint _conversionId
    )
    public
    view
    returns (address, uint, uint, ConversionState)
    {
        Conversion memory c = conversions[_conversionId];
        return (
            c.converterPlasma,
            c.bountyPaid,
            c.conversionTimestamp,
            c.state
        );
    }


    function updateRewardsBetweenInfluencers(
        address _converter,
        uint _conversionId,
        uint _bountyForDistribution
    )
    internal
    returns (uint)
    {

        //Get all the influencers
        address[] memory influencers = getReferrers(_converter);

        //Get array length
        uint numberOfInfluencers = influencers.length;

        uint i;
        uint reward;
        if(incentiveModel == IncentiveModel.VANILLA_AVERAGE) {
            reward = IncentiveModels.averageModelRewards(_bountyForDistribution, numberOfInfluencers);
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], reward, _conversionId);
            }
        } else if (incentiveModel == IncentiveModel.VANILLA_AVERAGE_LAST_3X) {
            uint rewardForLast;
            // Calculate reward for regular ones and for the last
            (reward, rewardForLast) = IncentiveModels.averageLast3xRewards(_bountyForDistribution, numberOfInfluencers);
            if(numberOfInfluencers > 0) {
                //Update equal rewards to all influencers but last
                for(i=0; i<numberOfInfluencers - 1; i++) {
                    updateReferrerMappings(influencers[i], reward, _conversionId);
                }
                //Update reward for last
                updateReferrerMappings(influencers[numberOfInfluencers-1], rewardForLast, _conversionId);
            }
        } else if(incentiveModel == IncentiveModel.VANILLA_POWER_LAW) {
            // Get rewards per referrer
            uint [] memory rewards = IncentiveModels.powerLawRewards(_bountyForDistribution, numberOfInfluencers, 2);
            //Iterate through all referrers and distribute rewards
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], rewards[i], _conversionId);
            }
        }

        return numberOfInfluencers;
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in one of the merkle_roots.
     *       this function can be called only after you called computeMerkleRoots one or more times until merkle_root is not 2
     * @param _influencer the influencer for which we want to get a Merkle proof
     * @return index to merkle_roots
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle_roots[index],
     *                 which prove that (_influencer,amount) are inside the root.
     *
     * The returned proof is only the first part of a proof to merkle_root.
     * The idea is that the code here does some of the work and the dApp code does the rest of the work to get a full proof
     * See https://github.com/2key/web3-alpha/commit/105b0b17ab3d20662b1e2171d84be25089962b68
     */
    function getMerkleProofBaseFromRoots(
        address _influencer // get proof for this influencer
    )
    internal
    view
    returns (uint, bytes32[])
    {

        if (isActiveInfluencer[_influencer] == false) {
            return (0, new bytes32[](0));
        }

        uint influencer_idx = activeInfluencer2idx[_influencer];

        uint start = N * (influencer_idx / N);

        influencer_idx = influencer_idx.sub(start);

        uint n = activeInfluencers.length.sub(start);

        if (n > N) {
            n = N;
        }

        bytes32[] memory hashes = new bytes32[](n);
        uint i;

        for (i = 0; i < n; i++) {
            address influencer = activeInfluencers[i+start];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }

        return (start/N, MerkleProof.getMerkleProofInternal(influencer_idx, hashes));
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in the the merkle_root.
     *       this function can be called only after you called computeMerkleRoots one or more times until merkle_root is not 2
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle_root,
     *                 which prove that (_influencer,amount) are inside the root.
     */
    function getMerkleProofFromRoots()
    public
    view
    returns (bytes32[])
    {
        address _influencer = msg.sender;
        bytes32[] memory proof0;
        uint start;
        (start, proof0) = getMerkleProofBaseFromRoots(_influencer);
        if (proof0.length == 0) {
            return proof0; // return failury
        }
        bytes32[] memory proof1 = MerkleProof.getMerkleProofInternal(start, merkle_roots);
        bytes32[] memory proof = new bytes32[](proof0.length + proof1.length);
        uint i;
        for (i = 0; i < proof0.length; i++) {
            proof[i] = proof0[i];
        }
        for (i = 0; i < proof1.length; i++) {
            proof[i+proof0.length] = proof1[i];
        }

        return proof;
    }


    function updateReferrerMappings(
        address referrerPlasma,
        uint reward,
        uint conversionId
    )
    internal
    {
        checkIsActiveInfluencerAndAddToQueue(referrerPlasma);
        referrerPlasma2Balances2key[referrerPlasma] = referrerPlasma2Balances2key[referrerPlasma].add(reward);
        referrerPlasma2TotalEarnings2key[referrerPlasma] = referrerPlasma2TotalEarnings2key[referrerPlasma].add(reward);
        referrerPlasma2EarningsPerConversion[referrerPlasma][conversionId] = reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] = referrerPlasmaAddressToCounterOfConversions[referrerPlasma].add(1);
    }

    /**
     * @notice Function to get all active influencers
     */
    function getActiveInfluencers()
    public
    view
    returns (address[])
    {
        return activeInfluencers;
    }


    function getNumberOfActiveInfluencers()
    public
    view
    returns (uint)
    {
        return activeInfluencers.length;
    }

    function ethereumOf(
        address _address
    )
    internal
    view
    returns (address)
    {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry");
        return ITwoKeyPlasmaRegistry(twoKeyPlasmaRegistry).plasma2ethereum(_address);
    }

    function getCounters()
    public
    view
    returns (uint[])
    {
        return counters;
    }

    function getAddressJoinedStatus(
        address _plasmaAddress
    )
    public
    view
    returns (bool)
    {
        if (_plasmaAddress == contractor
        || received_from[_plasmaAddress] != address(0)
        || balanceOf(_plasmaAddress) > 0) {
            return true;
        }
        return false;
    }

    function getSuperStatistics(
        address _address
    )
    public
    view
    returns (bool,bool,bool,address)
    {
        bool isReferrer = referrerPlasma2TotalEarnings2key[_address] > 0 ? true : false;
        bool isAddressConverter = isApprovedConverter[_address];
        bool isJoined = getAddressJoinedStatus(_address);

        return (isReferrer, isAddressConverter, isJoined, ethereumOf(_address));
    }

    function getAvailableBounty()
    public
    view
    returns (uint)
    {
        // Total bounty - bounty PAID for executed conversions
        return totalBountyForCampaign.sub(counters[6]);
    }

    function getInfluencersAndBalances(
        uint start,
        uint end
    )
    public
    view
    returns (address[], uint[])
    {
        uint[] memory balances = new uint[](end-start);
        address[] memory influencers = new address[](end-start);

        uint index = 0;
        for(index = start; index < end; index++) {
            address influencer = activeInfluencers[index];
            balances[index] = referrerPlasma2Balances2key[influencer];
            influencers[index] = influencer;
        }

        return (influencers, balances);
    }

    function getModeratorFeePercent()
    internal
    view
    returns (uint)
    {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry");
        return ITwoKeyPlasmaRegistry(twoKeyPlasmaRegistry).getModeratorFee();
    }


}
