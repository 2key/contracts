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

contract TwoKeyPlasmaCampaignNoReward is TwoKeyCampaignIncentiveModels, TwoKeyCampaignAbstract {

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

    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions;                   // [referrer][conversionId]

    mapping(address => bool) isApprovedConverter;               // Determinator if converter has already 1 successful conversion
    mapping(address => bytes) converterToSignature;             // If converter has a signature that means that he already converted
    mapping(address => uint) public converterToConversionId;    // Mapping converter to conversion ID he participated to

    bool public isValidated;                        // Validator if campaign is validated from maintainer side

    uint campaignStartTime;                         // Time when campaign start
    uint campaignEndTime;                           // Time when campaign ends

    event ConversionCreated(uint conversionId);     // Event which will be fired every time conversion is created


    modifier onlyMaintainer {                        // Modifier restricting calls only to maintainers
        require(isMaintainer(msg.sender));
        _;
    }

    modifier isCampaignValidated {                   // Checking if the campaign is created through TwoKeyPlasmaFactory
        require(isValidated == true);
        _;
    }

    /**
     * @notice          Function to check if campaign is active in terms of time set
     */
    modifier isCampaignActiveInTermsOfTime {
        require(campaignStartTime <= block.timestamp && block.timestamp <= campaignEndTime);
        _;
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

            if (received_from[new_address] == 0) {
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
    }


    /**
     * @notice          Function to update referral chain on executed/rejected conversions
     * @param           _converter is the converter address
     * @param           _conversionId is the id of conversion
     */
    function updateReferralChain(
        address _converter,
        uint _conversionId
    )
    internal
    {
        //Get all the influencers
        address[] memory influencers = getReferrers(_converter);
        //Get array length
        uint numberOfInfluencers = influencers.length;
        uint i;
        for(i=0; i<numberOfInfluencers; i++) {
            //Count conversion from referrer
            referrerPlasmaAddressToCounterOfConversions[influencers[i]] = referrerPlasmaAddressToCounterOfConversions[influencers[i]].add(1);
        }
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
        bool isReferrer = referrerPlasmaAddressToCounterOfConversions[_address] > 0 ? true : false;
        bool isAddressConverter = isApprovedConverter[_address];
        bool isJoined = getAddressJoinedStatus(_address);

        return (isReferrer, isAddressConverter, isJoined, ethereumOf(_address));
    }


    /**
     * @notice          Function to fetch how much conversions have been after selected influencer
     *
     * @param           influencerPlasma is the plasma address of influencer
     */
    function getReferrerToCounterOfConversions(
        address influencerPlasma
    )
    public
    view
    returns (uint)
    {
        return referrerPlasmaAddressToCounterOfConversions[influencerPlasma];
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


    function updateReputationPointsOnConversionExecutedEvent(
        address converter
    )
    internal
    {
        ITwoKeyPlasmaReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaReputationRegistry"))
        .updateReputationPointsForExecutedConversion(converter, contractor);
    }

    function updateReputationPointsOnConversionRejectedEvent(
        address converter
    )
    internal
    {
        ITwoKeyPlasmaReputationRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaReputationRegistry"))
        .updateReputationPointsForRejectedConversions(converter, contractor);
    }

}
