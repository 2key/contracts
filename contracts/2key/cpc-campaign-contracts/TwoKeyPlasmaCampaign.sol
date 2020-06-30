pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignAbstract.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";

import "../libraries/Call.sol";
import "../libraries/IncentiveModels.sol";
import "../libraries/MerkleProof.sol";

contract TwoKeyPlasmaCampaign is TwoKeyCampaignIncentiveModels, TwoKeyCampaignAbstract {

    uint constant N = 2048;  //constant number
    IncentiveModel incentiveModel;  //Incentive model for rewards

    /**
     0 pendingConverters
     1 approvedConverters
     2 rejectedConverters
     3 pendingConversions
     4 rejectedConversions
     5 executedConversions
     6 totalBountyPaid
     */
    uint [] counters;               // Array of counters, described above
    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key;                              // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions;                   // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;      // Earnings per conversion


    mapping(address => bool) isApprovedConverter;               // Determinator if converter has already 1 successful conversion
    mapping(address => bytes) converterToSignature;             // If converter has a signature that means that he already converted
    mapping(address => uint) public converterToConversionId;    // Mapping converter to conversion ID he participated to

    bool public isContractLocked;

    bool public isValidated;                        // Validator if campaign is validated from maintainer side
    address public contractorPublicAddress;         // Contractor address on public chain
    address public mirrorCampaignOnPublic;          // Address of campaign deployed to public eth network
    uint public moderatorTotalEarnings;             // Total rewards which are going to moderator

    uint campaignStartTime;                         // Time when campaign start
    uint campaignEndTime;                           // Time when campaign ends
    uint totalBountyForCampaign;                    // Total 2key tokens amount staked for the campaign
    uint bountyPerConversionWei;                    // Amount of 2key tokens which are going to be paid per conversion

    address[] activeInfluencers;                    // Active influencer means that he has at least on participation in successful conversion
    mapping(address => bool) isActiveInfluencer;    // Mapping which will say if influencer is active or not
    mapping(address => uint) activeInfluencer2idx;  // Mapping which will say what is influencers index in the array

    uint public rebalancingRatio;          //Initially rebalancing ratio is 1

    event ConversionCreated(uint conversionId);     // Event which will be fired every time conversion is created


    modifier onlyMaintainer {                       // Modifier restricting calls only to maintainers
        require(isMaintainer(msg.sender));
        _;
    }


    modifier isCampaignValidated {                  // Checking if the campaign is created through TwoKeyPlasmaFactory
        require(isValidated == true);
        _;
    }


    modifier contractNotLocked {                    // Modifier which requires that contract is not locked (locked == ended)
        require(isContractLocked == false);
        _;
    }

    modifier onlyIfContractActiveInTermsOfTime {    // Modifier which requires that contract is active in terms of time
        require(campaignStartTime <= block.timestamp && block.timestamp <= campaignEndTime);
        _;
    }

    /**
     * @dev             Transfer tokens from one address to another
     *
     * @param           _from address The address which you want to send tokens from ALREADY converted to plasma
     * @param           _to address The address which you want to transfer to ALREADY converted to plasma
     * @param           _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    internal
    {
        require(balances[_from] > 0);

        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(conversionQuota);
        totalSupply_ = totalSupply_.add(conversionQuota.sub(1));

        received_from[_to] = _from;
    }

    /**
     * @notice          Private function to set public link key to plasma address
     *
     * @param           me is the plasma address
     * @param           new_public_key is the new key user want's to set as his public key
     */
    function setPublicLinkKeyOf(
        address me,
        address new_public_key
    )
    internal
    {
        address old_address = public_link_key[me];
        if (old_address == address(0)) {
            public_link_key[me] = new_public_key;
        } else {
            require(old_address == new_public_key);
        }
        public_link_key[me] = new_public_key;
    }


    /**
      * @notice         Function which will unpack signature and get referrers, keys, and weights from it
      *
      * @param          sig is signature of the user
      * @param          _converter is the address of the converter
      */
    function getInfluencersKeysAndWeightsFromSignature(
        bytes sig,
        address _converter
    )
    internal
    view
    returns (address[],address[],address)
    {
        address old_address;
        assembly
        {
            old_address := mload(add(sig, 21))
        }

        old_address = old_address;
        address old_key = public_link_key[old_address];

        address[] memory influencers;
        address[] memory keys;
        (influencers, keys,) = Call.recoverSig(sig, old_key, _converter);

        require(
            influencers[influencers.length-1] == _converter
        );

        return (influencers, keys, old_address);
    }


    /**
     * @notice          Function to track arcs and make ref tree
     *
     * @param           sig is the signature user joins from
     * @param           _converter is the address of the converter

     */
    function distributeArcsBasedOnSignature(
        bytes sig,
        address _converter
    )
    internal
    {
        address[] memory influencers;
        address[] memory keys;
        address old_address;
        (influencers, keys,old_address) = getInfluencersKeysAndWeightsFromSignature(sig, _converter);
        uint i;
        address new_address;
        uint numberOfInfluencers = influencers.length;

        require(numberOfInfluencers <= 40);

        for (i = 0; i < numberOfInfluencers; i++) {
            new_address = influencers[i];

            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address);
            }
            old_address = new_address;

            if (i < keys.length) {
                setPublicLinkKeyOf(new_address, keys[i]);
            }
        }
    }

    /**
     * @notice 		    Function which will distribute arcs if that is necessary
     *
     * @param 		    _converter is the address of the converter
     * @param		    signature is the signature user is converting with
     *
     * @return 	        Distance between user and contractor
     */
    function distributeArcsIfNecessary(
        address _converter,
        bytes signature
    )
    internal
    returns (uint)
    {
        if(received_from[_converter] == address(0)) {
            distributeArcsBasedOnSignature(signature, _converter);
        }
        return getNumberOfUsersToContractor(_converter);
    }


    /**
     * @notice 		    Function to get number of influencers between submimtted user and contractor
     * @param 		    _user is the address of the user we're checking information
     *
     * 				    Example: contractor -> user1 -> user2 -> user3
     *				    Result for input(user3) = 2
     * @return		    Difference between user -> contractor
     */
    function getNumberOfUsersToContractor(
        address _user
    )
    public
    view
    returns (uint)
    {
        uint counter = 0;
        while(received_from[_user] != contractor) {
            _user = received_from[_user];
            require(_user != address(0));
            counter ++;
        }
        return counter;
    }

    /**
     * @notice          Function to get public link key of an address
     * @param           me is the address we're checking public link key
     */
    function publicLinkKeyOf(
        address me
    )
    public
    view
    returns (address)
    {
        return public_link_key[me];
    }

    /**
     * @notice          Function to get balance of influencer for his plasma address
     * @param           _influencer is the plasma address of influencer
     * @return          balance in 2KEY wei's units
     */
    function getReferrerPlasmaBalance(
        address _influencer
    )
    public
    view
    returns (uint)
    {
        return (referrerPlasma2Balances2key[_influencer]);
    }


    /**
     * @notice          Function to check if the user is maintainer or not
     * @param           _address is the address of the user
     * @return          true/false depending if he's maintainer or not
     */
    function isMaintainer(
        address _address
    )
    internal
    view
    returns (bool)
    {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry");
        return ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(_address);
    }


    /**
     * @notice          Function to validate that contracts plasma and public are well mirrored
     * @dev             This function can be called only by maintainer
     */
    function validateContractFromMaintainer()
    public
    onlyMaintainer
    {
        isValidated = true;
        // Emit the event to link plasma and public for TheGraph
        ITwoKeyPlasmaEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource"))
            .emitCPCCampaignMirrored(
                address(this),
                mirrorCampaignOnPublic
            );
    }


    function getReferrersBalancesAndTotalEarnings(
        address[] _referrerPlasmaList
    )
    public
    view
    returns (uint256[], uint256[])
    {
        uint numberOfAddresses = _referrerPlasmaList.length;
        uint256[] memory referrersPendingPlasmaBalance = new uint256[](numberOfAddresses);
        uint256[] memory referrersTotalEarningsPlasmaBalance = new uint256[](numberOfAddresses);

        for (uint i=0; i<numberOfAddresses; i++){
            referrersPendingPlasmaBalance[i] = referrerPlasma2Balances2key[_referrerPlasmaList[i]];
            referrersTotalEarningsPlasmaBalance[i] = referrerPlasma2TotalEarnings2key[_referrerPlasmaList[i]];
        }

        return (referrersPendingPlasmaBalance, referrersTotalEarningsPlasmaBalance);
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
        } else if (incentiveModel == IncentiveModel.NO_REFERRAL_REWARD) {
            for(i=0; i<numberOfInfluencers; i++) {
                //Count conversion from referrer
                checkIsActiveInfluencerAndAddToQueue(influencers[i]);
                referrerPlasmaAddressToCounterOfConversions[influencers[i]] = referrerPlasmaAddressToCounterOfConversions[influencers[i]].add(1);
            }
        }

        return numberOfInfluencers;
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


    /**
     * @notice          Will be called only once in a lifetime, immediately after campaign on public network is deployed
     * @dev             This can be only called by contractor
     * @param           _mirrorCampaign is the campaign address on public network
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
     * @notice          Function where maintainer will lock the contract
     */
    function lockContractFromMaintainer()
    public
    onlyMaintainer
    {
        isContractLocked = true;
    }



    /**
     * @notice          Function where maintainer will set on plasma network the total bounty amount
     *                  and how many tokens are paid per conversion for the influencers
     * @dev             This can be only called by maintainer
     * @param           _totalBounty is the total bounty for this campaign
     */
    function setTotalBounty(
        uint _totalBounty
    )
    public
    onlyMaintainer
    {
        // Leave that contractor can increase bounty if he wants
        totalBountyForCampaign = totalBountyForCampaign.add(_totalBounty);
    }


    /**
     * @notice          Function to return referrers participated in the referral chain
     * @param           customer is the one who converted
     * @return          array of referrer plasma addresses
     */
    function getReferrers(
        address customer
    )
    public
    view
    returns (address[])
    {
        address influencer = customer;
        uint numberOfInfluencers = getNumberOfUsersToContractor(influencer);

        address[] memory influencers = new address[](numberOfInfluencers);

        while (numberOfInfluencers > 0) {
            influencer = getReceivedFrom(influencer);
            numberOfInfluencers--;
            influencers[numberOfInfluencers] = influencer;
        }
        return influencers;
    }


    /**
     * @notice          Function to get referrer balances, total earnings they have and number
     *                  of conversions created from their link
     *
     * @param           _referrerAddress is the address of the referrer (plasma address)
     * @param           _sig is the signature of the referrer
     * @param           _conversionIds is the array of conversion ids we want earnings for
     */
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

        uint len = _conversionIds.length;
        uint[] memory earnings = new uint[](len);

        for(uint i=0; i<len; i++) {
            // Since this value is only accessible from here, we won't change it in the state but in the getter
            earnings[i] = getRebalancedReferrerEarningsPerConversion(_referrerAddress, _conversionIds[i]);
        }

        uint referrerBalance = referrerPlasma2Balances2key[_referrerAddress];
        return (referrerBalance, referrerPlasma2TotalEarnings2key[_referrerAddress], referrerPlasmaAddressToCounterOfConversions[_referrerAddress], earnings, _referrerAddress);
    }

    /**
     * @notice          Internal function to return rebalanced earning for conversion per influencer
     *                  That is the only value which is not changed in the contract state itself, since
     *                  it will require very complex transaction computation
     *
     * @param           _referrerAddress is the address of referrer
     * @param           conversionID is the id of conversion
     */
    function getRebalancedReferrerEarningsPerConversion(
        address _referrerAddress,
        uint conversionID
    )
    internal
    view
    returns (uint)
    {
        return referrerPlasma2EarningsPerConversion[_referrerAddress][conversionID].mul(rebalancingRatio).div(10**18);
    }


    /**
     * @notice          Internal helper function to recover the signature
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


    /**
     * @notice          Internal function to get moderator fee percent
     * @return          The fee in percentage which is going to moderator -> for now it's undivisible integer
     */
    function getModeratorFeePercent()
    internal
    view
    returns (uint)
    {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry");
        return ITwoKeyPlasmaRegistry(twoKeyPlasmaRegistry).getModeratorFee();
    }


    /**
     * @notice          Function to get available bounty at the moment
     *                  Practically it just substracts bountyPaid from totalBounty pool
     */
    function getAvailableBounty()
    public
    view
    returns (uint)
    {
        return totalBountyForCampaign.sub(moderatorTotalEarnings.add(counters[6]));             // Total bounty - bounty PAID for executed conversions
    }


    /**
     * @notice          Function to get influencers addresses and balances
     * @param           start is the starting index in the array
     * @param           end is the ending index of the campaign
     */
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


    /**
     * @notice          Function to get total bounty available and bounty per conversion
     */
    function getTotalBountyAndBountyPerConversion()
    public
    view
    returns (uint,uint)
    {
        return (totalBountyForCampaign, bountyPerConversionWei);
    }


    /**
     * @notice          Function to get if address is joined on-chain or not
     * @param           _plasmaAddress is the plasma address of the user
     *                  It can be converter, contractor, or simply an influencer
     * @return          True if address has joined
     */
    function getAddressJoinedStatus(
        address _plasmaAddress
    )
    public
    view
    returns (bool)
    {
        if (_plasmaAddress == contractor || received_from[_plasmaAddress] != address(0)) {
            return true;
        }
        return false;
    }


    /**
     * @notice           Function to get ethereum address for passed plasma address
     * @param            _address is the address we're getting ETH address for
     */
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


    /**
     * @notice          Function to get value of all counters
     */
    function getCounters()
    public
    view
    returns (uint[])
    {
        return counters;
    }


    /**
     * @notice          Function to get all active influencers
     */
    function getActiveInfluencers()
    public
    view
    returns (address[])
    {
        return activeInfluencers;
    }


    /**
     * @notice          Function to get number of active influencers
                        which is represented as the length of the array
                        they're stored in
     */
    function getNumberOfActiveInfluencers()
    public
    view
    returns (uint)
    {
        return activeInfluencers.length;
    }


    /**
     * @notice          Function to get super stats for an address which will include
     *                  if that address is an influencer, if he's a converter, also if he have joined the chain
                        and his ethereum address
     *
     * @return          tupled data
     */
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


    /**
     * @notice          Function to check if the address is the converter or not
     * @dev             If he has on-chain signature, that means he already converted
     * @param           converter is the address of the potential converter we're
                        calling this function for
     */
    function isConverter(
        address converter
    )
    public
    view
    returns (bool)
    {
        return converterToSignature[converter].length != 0 ? true : false;
    }


    /**
     * @notice          Internal function to make converter approved if it's his 1st conversion
     * @param           _converter is the plasma address of the converter
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
     * @notice          Function to check the balance of the referrer
     * @param           _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[_referrer];
    }


    /**
     * @notice          Function to update state of the contract that the bounty is withdrawn
     * @dev             Only contractor can update this function
     */
    function updateContractorWithdrawnBounty()
    public
    onlyContractor
    {
        // Make total bounty to be only what is for influencers, so another getter will return 0
        totalBountyForCampaign = counters[6];
    }


    /**
     * @notice          Function to return total bounty for campaign,
     *                  how much of the bounty is available and how much
     *                  of the total bounty is being paid
     */
    function getAvailableBountyForCampaign()
    public
    view
    returns (uint,uint,uint)
    {
        return (totalBountyForCampaign,totalBountyForCampaign.sub(moderatorTotalEarnings.add(counters[6])), moderatorTotalEarnings.add(counters[6]));
    }


    /**
     * @notice          Function which will be called only once, after we did rebalancing
     *                  on the mainchain contract, so it will adjust all values to rebalanced
     *                  rates. In case there was no
     *                  rebalancing, calling this function won't change anything in state
     *                  since rebalancingRatio initialy is 1 ETH and in all modifications it's divided
     *                  by 1 ETH so it results as neutral for multiplication
     *
     * @param           ratio is the rebalancingRatio
     */
    function adjustRebalancingResultsAndSetRatio(
        uint ratio
    )
    public
    onlyMaintainer
    {
        // Set the rebalancing ratio
        rebalancingRatio = ratio;

        uint one_eth = 10**18;
        // Rebalance fixed values
        totalBountyForCampaign = totalBountyForCampaign.mul(rebalancingRatio).div(one_eth);
        bountyPerConversionWei = bountyPerConversionWei.mul(rebalancingRatio).div(one_eth);

        // Rebalance earnings of moderator and influencers
        moderatorTotalEarnings = moderatorTotalEarnings.mul(rebalancingRatio).div(one_eth);
        counters[6] = counters[6].mul(rebalancingRatio).div(one_eth);
    }


    /**
     * @notice          Function where maintainer will adjust influencers earnings
     *                  after rebalancing is done on the contract. In case there was no
     *                  rebalancing, calling this function won't change anything in state
     *                  since rebalancingRatio initialy is 1 ETH and in all modifications it's divided
     *                  by 1 ETH so it results as neutral for multiplication
     *
     * @param           start is the starting index
     * @param           end is the ending index of influencers
     */
    function rebalanceInfluencersValues(
        uint start,
        uint end
    )
    public
    onlyMaintainer
    {
        uint i;

        uint one_eth = 10**18;
        for(i=start; i<end; i++) {
            address influencer = activeInfluencers[i];
            referrerPlasma2Balances2key[influencer] = referrerPlasma2Balances2key[influencer].mul(rebalancingRatio).div(one_eth);
            referrerPlasma2TotalEarnings2key[influencer] = referrerPlasma2TotalEarnings2key[influencer].mul(rebalancingRatio).div(one_eth);
        }
    }


    /**
     * @notice          compute a merkle proof that influencer and amount are in one of the merkle_roots.
     *                  this function can be called only after you called computeMerkleRoots one or more times until merkle_root is not 2
     * @param           _influencer the influencer for which we want to get a Merkle proof
     * @return          index to merkle_roots
     * @return          proof - array of hashes that can be used with _influencer and amount to compute the merkle_roots[index],
     *                  which prove that (_influencer,amount) are inside the root.
     *
     *                  The returned proof is only the first part of a proof to merkle_root.
     *                  The idea is that the code here does some of the work and the dApp code does the rest
     *                  of the work to get a full proof
     *                  See https://github.com/2key/web3-alpha/commit/105b0b17ab3d20662b1e2171d84be25089962b68
     */
    //    function getMerkleProofBaseFromRoots(
    //        address _influencer
    //    )
    //    internal
    //    view
    //    returns (uint, bytes32[])
    //    {
    //
    //        if (isActiveInfluencer[_influencer] == false) {
    //            return (0, new bytes32[](0));
    //        }
    //
    //        uint influencer_idx = activeInfluencer2idx[_influencer];
    //
    //        uint start = N * (influencer_idx / N);
    //
    //        influencer_idx = influencer_idx.sub(start);
    //
    //        uint n = activeInfluencers.length.sub(start);
    //
    //        if (n > N) {
    //            n = N;
    //        }
    //
    //        bytes32[] memory hashes = new bytes32[](n);
    //        uint i;
    //
    //        for (i = 0; i < n; i++) {
    //            address influencer = activeInfluencers[i+start];
    //            uint amount = referrerPlasma2Balances2key[influencer];
    //            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
    //        }
    //
    //        return (start/N, MerkleProof.getMerkleProofInternal(influencer_idx, hashes));
    //    }

    /**
     * @notice          compute a merkle proof that influencer and amount are in the the merkle_root.
     *                  this function can be called only after you called computeMerkleRoots one or
     *                  more times until merkle_root is not 2
     * @return          proof - array of hashes that can be used with _influencer and amount to compute the merkle_root,
     *                  which prove that (_influencer,amount) are inside the root.
     */
    //    function getMerkleProofFromRoots()
    //    public
    //    view
    //    returns (bytes32[])
    //    {
    //        address _influencer = msg.sender;
    //        bytes32[] memory proof0;
    //        uint start;
    //        (start, proof0) = getMerkleProofBaseFromRoots(_influencer);
    //        if (proof0.length == 0) {
    //            return proof0; // return failury
    //        }
    //        bytes32[] memory proof1 = MerkleProof.getMerkleProofInternal(start, merkle_roots);
    //        bytes32[] memory proof = new bytes32[](proof0.length + proof1.length);
    //        uint i;
    //        for (i = 0; i < proof0.length; i++) {
    //            proof[i] = proof0[i];
    //        }
    //        for (i = 0; i < proof1.length; i++) {
    //            proof[i+proof0.length] = proof1[i];
    //        }
    //
    //        return proof;
    //    }


    //    /**
    //     * @notice          compute a merkle root of the active influencers and the amount they received.
    //     *                  (active influencer is an influencer that received a bounty)
    //     *                  this function needs to be called many times until merkle_root is not 2.
    //     *                  In each call a merkle tree of up to N leaves (pair of active-influencer and amount) is
    //     *                  computed and the result is added to merkle_roots. N should be a power of 2 for example N=2048.
    //     *                  On all calls you have to use the same N value.
    //     *                  Once you the leaves are computed you need to call this function one more time to compute the
    //     *                  merkle_root of the entire tree from the intermidate results in merkle_roots
    //     */
    //    function computeMerkleRoots()
    //    public
    //    onlyMaintainer
    //    {
    //        require(merkleRoot == 0 || merkleRoot == 2, 'merkle root already defined');
    //
    //        uint numberOfInfluencers = activeInfluencers.length;
    //        if (numberOfInfluencers == 0) {
    //            merkleRoot = bytes32(1);
    //            return;
    //        }
    //        merkleRoot = bytes32(2); // indicate that the merkle root is being computed
    //
    //        uint start = merkle_roots.length * N;
    //        if (start >= numberOfInfluencers) {
    //            merkleRoot = MerkleProof.computeMerkleRootInternal(merkle_roots);
    //            return;
    //        }
    //
    //        uint n = numberOfInfluencers - start;
    //        if (n > N) {
    //            n = N;
    //        }
    //        bytes32[] memory hashes = new bytes32[](n);
    //        for (uint i = 0; i < n; i++) {
    //            address influencer = activeInfluencers[i+start];
    //            uint amount = referrerPlasma2Balances2key[influencer];
    //            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
    //        }
    //        merkle_roots.push(MerkleProof.computeMerkleRootInternal(hashes));
    //    }

}
