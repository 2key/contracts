pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignAbstract.sol";

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeyPlasmaEventSource.sol";
import "../interfaces/ITwoKeyPlasmaReputationRegistry.sol";

import "../libraries/Call.sol";
import "../libraries/IncentiveModels.sol";
import "../libraries/MerkleProof.sol";

contract TwoKeyPlasmaCampaign is TwoKeyCampaignIncentiveModels, TwoKeyCampaignAbstract {

    uint constant N = 2048;  //constant number
    IncentiveModel incentiveModel;  //Incentive model for rewards


    struct Payment {
        uint rebalancingRatio;
        uint timestamp;
        bool isReferrerPaid;
    }

    event RebalancedValue(
        address referrer,
        uint currentRate2KEYUSD,
        uint ratio
    );

    /**
     0 pendingConverters
     1 approvedConverters
     2 rejectedConverters
     3 pendingConversions
     4 rejectedConversions
     5 executedConversions
     6 totalBountyPaidToReferrers
     */
    uint [] counters;               // Array of counters, described above

    // Referrer necessary data

    uint numberOfPaidClicksAchieved;
    uint numberOfTotalPaidClicksSupported;
    uint moderatorFeePerConversion;

    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key;                              // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions;                   // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;      // Earnings per conversion
    mapping(address => Payment) public referrerToPayment;

    // Converter necessary data
    mapping(address => bool) isApprovedConverter;               // Determinator if converter has already 1 successful conversion
    mapping(address => bytes) converterToSignature;             // If converter has a signature that means that he already converted
    mapping(address => uint) public converterToConversionId;    // Mapping converter to conversion ID he participated to

    bool isBudgetedDirectlyWith2KEY;

    uint public activationTimestamp;

    // public available integers
    bool public isContractLocked;
    uint public moderatorTotalEarnings;             // Total rewards which are going to moderator
    uint public initialRate2KEY;                   // Rate at which 2KEY is bought at campaign creation
    bool public isValidated;

    // Internal contract values
    uint campaignStartTime;                         // Time when campaign start
    uint campaignEndTime;                           // Time when campaign ends
    uint totalBountyForCampaign;                    // Total 2key tokens amount staked for the campaign
    uint bountyPerConversionWei;                    // Amount of 2key tokens which are going to be paid per conversion


    address[] public activeInfluencers;                    // Active influencer means that he has at least on participation in successful conversion
    mapping(address => bool) isActiveInfluencer;    // Mapping which will say if influencer is active or not

    /**
     * ------------------------------------------------------------------------------------
     *                          MODIFIERS AND EVENTS
     * ------------------------------------------------------------------------------------
     */

    // Modifier restricting calls only to maintainers
    modifier onlyMaintainer {
        require(isMaintainer(msg.sender));
        _;
    }

    // Checking if the campaign is created through TwoKeyPlasmaFactory
    modifier isBountyAdded {
        require(totalBountyForCampaign > 0);
        _;
    }

    // Restricting calls only to plasma campaigns payments handler contract
    modifier onlyPlasmaBudgetPaymentsHandler {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaBudgetCampaignsPaymentsHandler"));
        _;
    }

    // Event which will be fired every time conversion is created
    event ConversionCreated(
        uint conversionId
    );

    /**
     * ------------------------------------------------------------------------------------
     *                          Internal contract functions
     * ------------------------------------------------------------------------------------
     */

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
     * @notice          Function to check if campaign is active in terms of time set
     */
    function isCampaignActiveInTermsOfTime()
    internal
    view
    returns (bool)
    {
        if(campaignStartTime <= block.timestamp && block.timestamp <= campaignEndTime) {
            return true;
        }
        return false;
    }


    /**
     * @notice          Function to check if campaign is ended
     */
    function isCampaignEnded()
    internal
    view
    returns (bool)
    {
        return isContractLocked;
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
     * @dev             Transfer tokens from one address to another
     *
     * @param           _from address The address which you want to send tokens from ALREADY converted to plasma
     * @param           _to address The address which you want to transfer to ALREADY converted to plasma
     */
    function transferFrom(
        address _from,
        address _to,
        bool isConversionApproval
    )
    internal
    {
        // Initially arcs to sub are 0
        uint arcsToSub = 0;

        // If previous user in chain has arcs then we're taking them
        if(balances[_from] > 0) {
            arcsToSub = 1;
        }

        // If it's conversion approval we require that previous user has arcs
        if(isConversionApproval == true) {
            require(arcsToSub == 1);
        }


        balances[_from] = balances[_from].sub(arcsToSub);
        balances[_to] = balances[_to].add(conversionQuota*arcsToSub);
        totalSupply_ = totalSupply_.add((conversionQuota*arcsToSub).sub(arcsToSub));

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
        address _converter,
        bool isConversionApproval
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

            if (received_from[new_address] == address(0)) {
                transferFrom(old_address, new_address, isConversionApproval);
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
        bytes signature,
        bool isConversionApproval
    )
    internal
    returns (uint)
    {
        if(received_from[_converter] == address(0)) {
            distributeArcsBasedOnSignature(signature, _converter, isConversionApproval);
        }
        return getNumberOfUsersToContractor(_converter);
    }


    /**
     * @notice          Function to call TwoKeyPlasmaReputationRegistry contract and update
     *                  reputation points for the influencers after conversion is executed
     *
     * @param           converter is the address of the converter which got rejected
     */
    function updateReputationPointsOnConversionExecutedEvent(
        address converter
    )
    internal
    {
        ITwoKeyPlasmaReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaReputationRegistry"))
        .updateReputationPointsForExecutedConversion(converter, contractor);
    }


    /**
     * @notice          Function to call TwoKeyPlasmaReputationRegistry contract and update
     *                  reputation points for the influencers after conversion is rejected
     *
     * @param           converter is the address of the converter which got rejected
     */
    function updateReputationPointsOnConversionRejectedEvent(
        address converter
    )
    internal
    {
        ITwoKeyPlasmaReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaReputationRegistry"))
        .updateReputationPointsForRejectedConversions(converter, contractor);
    }

    /**
     * @notice          Function to update rewards between influencers when conversion gets executed
     *
     * @param           _converter is the address of converter
     * @param           _conversionId is the ID of conversion
     * @param           _bountyForDistribution is the total bounty for distribution for that conversion
     */
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
     * @notice          Internal function to update referrer mappings
     * @param           referrerPlasma is referrer plasma address
     * @param           reward is the reward referrer received
     * @param           conversionId is the id of conversion for which influencer gets rewarded
     */
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
     * @notice          Function to check if influencer is persisted on the contract and add him to queue
     * @param           _influencer is the address of influencer
     */
    function checkIsActiveInfluencerAndAddToQueue(
        address _influencer
    )
    internal
    {
        if(!isActiveInfluencer[_influencer]) {
            activeInfluencers.push(_influencer);
            isActiveInfluencer[_influencer] = true;
        }
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
     * @notice          Internal function to get moderator fee percent
     * @return          The fee in percentage which is going to moderator -> for now it's undivisible integer
     */
    function getModeratorFeePercent()
    internal
    view
    returns (uint)
    {
        return ITwoKeyPlasmaRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry")).getModeratorFee();
    }


    /**
     * @notice          Function to rebalance selected value, assuming both
     *                  input parameters are in wei units
     *
     * @param           value to be rebalanced
     * @param           ratio is the ratio by which we rebalance
     */
    function rebalanceValue(
        uint value,
        uint ratio
    )
    internal
    pure
    returns (uint)
    {
        return value.mul(ratio).div(10**18);
    }

    /**
     * @notice          Function to get rebalancing ratio for selected referrer
     *                  If the rebalancing ratio is not submitted yet, it will
     *                  default to 1 ETH
     *
     * @param           _referrerPlasma is referrer plasma address
     */
    function getRebalancingRatioForReferrer(
        address _referrerPlasma
    )
    internal
    view
    returns (uint)
    {
        Payment memory p = referrerToPayment[_referrerPlasma];
        return p.rebalancingRatio != 0 ? p.rebalancingRatio : 10**18;
    }

    /**
     * ------------------------------------------------------------------------------------
     *                          Public getters
     * ------------------------------------------------------------------------------------
     */

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
     * @param           _referrer is the plasma address of influencer
     * @return          balance in 2KEY wei's units
     */
    function getReferrerPlasmaBalance(
        address _referrer
    )
    public
    view
    returns (uint)
    {
        return (
            rebalanceValue(
                referrerPlasma2Balances2key[_referrer],
                getRebalancingRatioForReferrer(_referrer)
            )
        );
    }

    /**
     * @notice          Function to get referrer non rebalanced earnings
     */
    function getReferrerNonRebalancedBalance(
        address _referrer
    )
    public
    view
    returns (uint)
    {
        return referrerPlasma2Balances2key[_referrer];
    }


    /**
     * @notice          Function to get referrers balances and total earnings
     * @param           _referrerPlasmaList the list of referrers
     */
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
            address referrer = _referrerPlasmaList[i];

            uint referrerRebalancingRatio = getRebalancingRatioForReferrer(referrer);

            referrersPendingPlasmaBalance[i] = rebalanceValue(
                referrerPlasma2Balances2key[referrer],
                referrerRebalancingRatio
            );

            referrersTotalEarningsPlasmaBalance[i] = rebalanceValue(
                referrerPlasma2TotalEarnings2key[referrer],
                referrerRebalancingRatio
            );
        }

        return (referrersPendingPlasmaBalance, referrersTotalEarningsPlasmaBalance);
    }


    /**
     * @notice          Function where maintainer will lock the contract
     */
    function lockContractFromMaintainer()
    public
    onlyMaintainer
    {
        require(block.timestamp >= activationTimestamp.add(86400));
        isContractLocked = true;
    }


    /**
     * @notice          Function where maintainer will set on plasma network the total bounty amount
     *                  and how many tokens are paid per conversion for the influencers
     * @dev             This can be only called by maintainer, and only once.
     * @param           _totalBounty is the total bounty for this campaign
     */
    function setInitialParamsAndValidateCampaign(
        uint _totalBounty,
        uint _initialRate2KEY,
        uint _bountyPerConversion2KEY,
        bool _isBudgetedDirectlyWith2KEY
    )
    public
    onlyMaintainer
    {
        // Require that campaign is not previously validated
        require(isValidated == false);
        // Set the activation timestamp
        activationTimestamp = block.timestamp;
        // Set total bounty for campaign
        totalBountyForCampaign = _totalBounty;
        // Calculate moderator fee per every conversion
        moderatorFeePerConversion = _bountyPerConversion2KEY.mul(getModeratorFeePercent()).div(100);
        // Set bounty per conversion
        bountyPerConversionWei = _bountyPerConversion2KEY.sub(moderatorFeePerConversion);
        // Set initial rate at which tokens are purchased
        initialRate2KEY = _initialRate2KEY;
        // It's going to round the value.
        if(bountyPerConversionWei == 0 || totalBountyForCampaign == 0) {
            numberOfTotalPaidClicksSupported = 0;
        } else {
            numberOfTotalPaidClicksSupported = totalBountyForCampaign.div(_bountyPerConversion2KEY);
        }
        // Set if campaign is budgeted directly with 2KEY
        isBudgetedDirectlyWith2KEY = _isBudgetedDirectlyWith2KEY;
        isValidated = true;
    }


    /**
     * @notice          At the moment when we want to do payouts for influencers, we
     *                  rebalance their values against price at which tokens were bought.
     */
    function computeAndSetRebalancingRatioForReferrer(
        address _referrer,
        uint _currentRate2KEY
    )
    public
    onlyPlasmaBudgetPaymentsHandler
    returns (uint,uint)
    {

        uint rebalancingRatio = 10**18;

        // This is in case inventory NOT added directly as 2KEY
        if(isBudgetedDirectlyWith2KEY == false) {
            rebalancingRatio = initialRate2KEY.mul(10**18).div(_currentRate2KEY);
             emit RebalancedValue(
                _referrer,
                _currentRate2KEY,
                rebalancingRatio
             );
        }

        Payment memory p = Payment(rebalancingRatio, block.timestamp, false);
        referrerToPayment[_referrer] = p;

        return (getReferrerPlasmaBalance(_referrer), referrerPlasma2Balances2key[_referrer]);
    }

    /**
     * @notice          Function which will mark that referrer received payment for this campaign
     * @param           _referrer is the referrer address being receiving funds
     */
    function markReferrerReceivedPaymentForThisCampaign(
        address _referrer
    )
    public
    onlyPlasmaBudgetPaymentsHandler
    {
        // Take current payment structure for the referrer
        Payment memory p = referrerToPayment[_referrer];

        // Require that referrer is not already paid since he can't get paid twice
        require(p.isReferrerPaid == false);

        // Set that referrer is paid
        p.isReferrerPaid = true;

        // Store in mapping
        referrerToPayment[_referrer] = p;
    }

    /**
     * @notice          Function to get total referrer rewards and current balance for that campaign
     *                  Which can be either same or 0.
     * @param           _referrer is the plasma address of referrer
     */
    function getReferrerRebalancedRewardsAndPaymentStatus(
        address _referrer
    )
    public
    view
    returns (uint,bool)
    {
        Payment memory p = referrerToPayment[_referrer];

        return (
            getReferrerPlasmaBalance(_referrer),
            p.isReferrerPaid
        );
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
            influencers[numberOfInfluencers] = influencer;  //TODO this orders influencers in their place on the chain, so contractor(if he's here) will be o, and the last one will be the last index
        }
        return influencers;
    }


    /**
     * @notice          Function to get referrer balances, total earnings they have and number
     *                  of conversions created from their link
     *
     * @param           _referrerAddress is the address of the referrer (plasma address)
     * @param           _conversionIds is the array of conversion ids we want earnings for
     */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(
        address _referrerAddress,
        uint[] _conversionIds
    )
    public
    view
    returns (uint,uint,uint,uint[])
    {
        uint len = _conversionIds.length;
        uint[] memory rebalancedEarnings = new uint[](len);

        uint rebalancingRatioForInfluencer = getRebalancingRatioForReferrer(_referrerAddress);

        for(uint i=0; i<len; i++) {
            uint conversionId = _conversionIds[i];
            // Since this value is only accessible from here, we won't change it in the state but in the getter
            rebalancedEarnings[i] = rebalanceValue(
                referrerPlasma2EarningsPerConversion[_referrerAddress][conversionId],
                rebalancingRatioForInfluencer
            );
        }

        return (
            rebalanceValue(referrerPlasma2Balances2key[_referrerAddress], rebalancingRatioForInfluencer),
            rebalanceValue(referrerPlasma2TotalEarnings2key[_referrerAddress], rebalancingRatioForInfluencer),
            referrerPlasmaAddressToCounterOfConversions[_referrerAddress],
            rebalancedEarnings
        );
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
        return totalBountyForCampaign.sub(counters[6]);             // Total bounty - bounty PAID for executed conversions
    }


    /**
     * @notice          Function to get total bounty available and bounty per conversion
     */
    function getBountyAndClicksStats()
    public
    view
    returns (uint,uint,uint,uint)
    {
        return (totalBountyForCampaign, bountyPerConversionWei.add(moderatorFeePerConversion), numberOfPaidClicksAchieved, numberOfTotalPaidClicksSupported);
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
    function getActiveInfluencers(
        uint start,
        uint end
    )
    public
    view
    returns (address[])
    {
        address[] memory influencers = new address[](end-start);

        uint index = 0;
        uint i = 0;
        for(i = start; i < end; i++) {
            address influencer = activeInfluencers[i];
            influencers[index] = influencer;
            index++;
        }

        return influencers;
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
        bool isReferrer = isActiveInfluencer[_address];
        bool isAddressConverter = isApprovedConverter[_address];
        bool isJoined = getAddressJoinedStatus(_address);

        return (isReferrer, isAddressConverter, isJoined, ethereumOf(_address));
    }


    /**
     * @notice          Function to get total rewards to be distributed to referrer
     *                  as well as total moderator earnings for this campaign
     */
    function getTotalReferrerRewardsAndTotalModeratorEarnings()
    public
    view
    returns (uint,uint)
    {
        return (numberOfPaidClicksAchieved.mul(bountyPerConversionWei), moderatorTotalEarnings);
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

}
