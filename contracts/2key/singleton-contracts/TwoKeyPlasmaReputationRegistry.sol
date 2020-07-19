pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaReputationRegistryStorage.sol";

import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";

contract TwoKeyPlasmaReputationRegistry is Upgradeable {
    /**
     * Contract to handle reputation points on plasma conversions for Budget campaigns
     * For all successful conversions initial reward is 1
     * For all rejected conversions initial penalty is 0.5
     */

    ITwoKeyPlasmaReputationRegistryStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;


    /**
     * Storage keys
     */
    string constant _plasmaAddress2contractorGlobalReputationScoreWei = "plasmaAddress2contractorGlobalReputationScoreWei";
    string constant _plasmaAddress2converterGlobalReputationScoreWei = "plasmaAddress2converterGlobalReputationScoreWei";
    string constant _plasmaAddress2referrerGlobalReputationScoreWei = "plasmaAddress2referrerGlobalReputationScoreWei";

    string constant _plasmaAddress2Role2Feedback = "plasmaAddress2Role2Feedback";

    /**
     * @notice          Event which will be emitted every time reputation of a user
     *                  is getting changed. Either positive or negative.
     */
    event ReputationUpdated(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET,FEEDBACK)
        int _points
    );

    /**
     * @notice          Function used as replacement for constructor, can be called only once
     *
     * @param           _twoKeyPlasmaSingletonRegistry is the address of TwoKeyPlasmaSingletonRegistry
     * @param           _proxyStorage is the address of proxy for storage
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaReputationRegistryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice          Modifier restricting access to the function only to campaigns
     *                  created using TwoKeyPlasmaFactory contract
     */
    modifier onlyBudgetCampaigns {
        require(
            ITwoKeyPlasmaFactory(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaFactory"))
            .isCampaignCreatedThroughFactory(msg.sender)
        );
        _;
    }

    /**
    * @notice          Modifier which will be used to restrict calls to only maintainers
    */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }


    /**
     * @notice          Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function isRoleExisting(
        string _role
    )
    internal
    view
    returns (bool) {
        if(
            keccak256(_role) == keccak256("CONVERTER") ||
            keccak256(_role) == keccak256("REFERRER") ||
            keccak256(_role) == keccak256("CONTRACTOR")
        ) {
                return true;
        }
        return false;
    }

    /**
     * @notice          Internal wrapper function to fetch referrers for specific converter
     * @param           campaign is the address of the campaign
     * @param           converter is the address of converter for whom we want to fetch
     *                  the referrers
     */
    function getReferrers(
        address campaign,
        address converter
    )
    internal
    view
    returns (address[])
    {
        return ITwoKeyCPCCampaignPlasma(campaign).getReferrers(converter);
    }

    function addPositiveFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        int _pointsGained
    )
    public
    onlyMaintainer
    {
        require(isRoleExisting(_role) == true);
        // generate key hash for current score
        bytes32 keyHashPlasmaAddressToFeedback = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, _role);
        // Load current score
        int currentScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedback);
        // Add to current score points gained
        PROXY_STORAGE_CONTRACT.setInt(keyHashPlasmaAddressToFeedback, currentScore + _pointsGained);

        emit ReputationUpdated(
            _plasmaAddress,
            _role,
            "FEEDBACK",
            _pointsGained
        );
    }

    function addNegativeFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        int _pointsLost
    )
    public
    onlyMaintainer
    {
        require(isRoleExisting(_role) == true);
        // generate key hash for current score
        bytes32 keyHashPlasmaAddressToFeedback = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, _role);
        // Load current score
        int currentScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedback);
        // Deduct from current score points lost
        PROXY_STORAGE_CONTRACT.setInt(keyHashPlasmaAddressToFeedback, currentScore - _pointsLost);

        emit ReputationUpdated(
            _plasmaAddress,
            _role,
            "FEEDBACK",
            _pointsLost*(-1)
        );
    }

    /**
     * @notice          Function to update reputation points for executed conversions
     *
     * @param           converter is the address who converted
     * @param           contractor is the address who created campaign
     */
    function updateReputationPointsForExecutedConversion(
        address converter,
        address contractor
    )
    public
    onlyBudgetCampaigns
    {
        int initialRewardWei = (10**18);

        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + initialRewardWei);

        emit ReputationUpdated(
            contractor,
            "CONTRACTOR",
            "BUDGET",
            initialRewardWei
        );

        bytes32 keyHashConverterScore = keccak256(_plasmaAddress2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + initialRewardWei);

        emit ReputationUpdated(
            converter,
            "CONVERTER",
            "BUDGET",
            initialRewardWei
        );

        address[] memory referrers = getReferrers(msg.sender, converter);

        for(int i=0; i<int(referrers.length); i++) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(i+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + reward);
            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "BUDGET",
                reward
            );
        }

    }


    /**
     * @notice          Function to update reputation points for rejected conversions
     *
     * @param           converter is the address who converted
     * @param           contractor is the address who created campaign
     */
    function updateReputationPointsForRejectedConversions(
        address converter,
        address contractor
    )
    public
    onlyBudgetCampaigns
    {
        int initialPunishmentWei = (10**18) / 2;

        bytes32 keyHashConverterScore = keccak256(_plasmaAddress2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore - initialPunishmentWei);

        emit ReputationUpdated(
            converter,
            "CONVERTER",
            "BUDGET",
            initialPunishmentWei*(-1)
        );


        address[] memory referrers = getReferrers(msg.sender, converter);

        int length = int(referrers.length);

        for(int i=0; i<length; i++) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialPunishmentWei/(i+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "BUDGET",
                reward*(-1)
            );
        }

        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, contractor);

        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        int contractorPunishment = initialPunishmentWei/(length+1);

        PROXY_STORAGE_CONTRACT.setInt(
            keyHashContractorScore,
                contractorScore - contractorPunishment
        );

        emit ReputationUpdated(
            contractor,
            "CONTRACTOR",
            "BUDGET",
            contractorPunishment*(-1)
        );
    }


    /**
     * @notice          Function to get reputation and feedback score in case he's an influencer & converter
     */
    function getReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int,int,int,int)
    {
        bytes32 keyHashConverterScore = keccak256(_plasmaAddress2converterGlobalReputationScoreWei, _plasmaAddress);
        int converterReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);

        bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, _plasmaAddress);
        int referrerReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);

        bytes32 keyHashPlasmaAddressToFeedbackAsConverter = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONVERTER");
        int converterFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedbackAsConverter);

        bytes32 keyHashPlasmaAddressToFeedbackAsReferrer = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "REFERRER");
        int referrerFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedbackAsReferrer);

        return (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore
        );
    }

    /**
     * @notice          Function to get global reputation for specific user
     */
    function getGlobalReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int converterReputationScore;
        int referrerReputationScore;
        int converterFeedbackScore;
        int referrerFeedbackScore;

        (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore
        ) = getReputationForUser(_plasmaAddress);

        return (converterReputationScore + referrerReputationScore + converterFeedbackScore + referrerFeedbackScore);
    }


    /**
     * @notice          Function to get reputation and feedback score in case he's a business page (contractor)
     */
    function getReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int,int)
    {
        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, _plasmaAddress);
        int contractorReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        bytes32 keyHashPlasmaAddressToFeedbackAsContractor = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONTRACTOR");
        int contractorFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedbackAsContractor);

        return (
            contractorReputationScore,
            contractorFeedbackScore
        );
    }

    /**
     * @notice          Function to get global reputation for contractor (business)
     */
    function getGlobalReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int contractorReputationScore;
        int contractorFeedbackScore;
        (contractorReputationScore,contractorFeedbackScore) = getReputationForContractor(_plasmaAddress);

        return (contractorReputationScore + contractorFeedbackScore);
    }


    /**
     * @notice          Function to return global reputation for requested users
     * @param           addresses is an array of plasma addresses of users
     */
    function getGlobalReputationForUsers(
        address [] addresses
    )
    public
    view
    returns (int[]) {
        uint len = addresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForUser(addresses[i]);
        }

        return (reputations);
    }

    /**
     * @notice          Function to get global reputations for contractors
     * @param           addresses is an array of plasma addresses of contractors (businesses)
     */
    function getGlobalReputationForContractors(
        address [] addresses
    )
    public
    view
    returns (int[])
    {
        uint len = addresses.length;

        int [] memory reputations = new int[](len);

        uint i;
        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForContractor(addresses[i]);
        }

        return (reputations);
    }
}
