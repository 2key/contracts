pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaReputationRegistryStorage.sol";

import "../interfaces/ITwoKeyCPCCampaignPlasma.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "./TwoKeyPlasmaRegistry.sol";

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
    string constant _plasmaAddress2signupBonus = "plasmaAddress2signupBonus";

    string constant _plasmaAddress2Role2Feedback = "plasmaAddress2Role2Feedback";

    /**
     * @notice          Event which will be emitted every time reputation of a user
     *                  is getting changed. Either positive or negative.
     */
    event ReputationUpdated(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET,FEEDBACK)
        int _points,
        address _campaignAddress
    );

    event FeedbackSubmitted(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET)
        int _points,
        address _reporterPlasma,
        address _campaignAddress
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


    /**
     * @notice          Function to check if role exists.
     * @param           _role is the role in feedback submitted from maintainer
     */
    function isRoleExisting(
        string _role
    )
    internal
    pure
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


    /**
     * @notice          Function to update converter score
     * @param           converter is converter plasma address
     * @param           reward is amount of points converter earned or lost
     * @param           campaignType is the campaign type for which converter earned/lost points
     */
    function updateConverterScore(
        address converter,
        int reward,
        string campaignType
    )
    internal
    {
        bytes32 keyHashConverterScore = keccak256(_plasmaAddress2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + reward);

        emit ReputationUpdated(
            converter,
            "CONVERTER",
            campaignType,
            reward,
            msg.sender
        );
    }


    /**
     * @notice          Function to handle logic operation of updating reputation score between users
     * @param           converter is campaign converter, and in this case he's getting rewarded with
     *                  initialRewardWei points
     * @param           initialRewardWei is number of points for successful action, distributed
     *                  in a way so every next user gets 1/n *initialRewardWei
     * @param           campaignType is type of the campaign. Used mostly because of events.
     */
    function updateReputationPointsForExecutedConversionInternal(
        address converter,
        address contractor,
        int initialRewardWei,
        string campaignType
    )
    internal
    {
        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + initialRewardWei);

        emit ReputationUpdated(
            contractor,
            "CONTRACTOR",
            campaignType,
            initialRewardWei,
            msg.sender
        );

        updateConverterScore(converter, initialRewardWei, campaignType);

        address[] memory referrers = getReferrers(msg.sender, converter);

        int j;

        for(int i=int(referrers.length)-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);

            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                campaignType,
                reward,
                msg.sender
            );

            j++;
        }
    }


    /**
     * @notice          Function to handle logic operation of updating reputation score between users
     * @param           converter is campaign converter, and in this case he's getting punished as like
     *                  he's the first influencer in the referral chain
     * @param           initialPunishmentWei is number of points for reduction after unsuccessful action
     * @param           campaignType is type of the campaign. Used mostly because of events.
     */
    function updateReputationPointsForRejectedConversionsInternal(
        address converter,
        address contractor,
        int initialPunishmentWei,
        string campaignType
    )
    internal
    {
        // Here we punish converter so he gets negative points
        updateConverterScore(
            converter,
            initialPunishmentWei * (-1),
            campaignType
        );

        address[] memory referrers = getReferrers(msg.sender, converter);

        int length = int(referrers.length);

        int j=0;

        for(int i=length-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialPunishmentWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "BUDGET",
                reward*(-1),
                msg.sender
            );
            j++;
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
            contractorPunishment*(-1),
            msg.sender
        );
    }


    /**
     * @notice          Function to add positive feedback for user from maintainer
     * @param           _plasmaAddress is user plasma address
     * @param           _role is representing as which role user received this feedback
     * @param           _type is representing mostly if the feedback was for monetary/budget campaigns
     * @param           _pointsGained is amount of points earned for this feedback
     * @param           _reporterPlasma is address of user who submitted this feedback
     * @param           _campaignAddress is address of campaign for which user submitted feedback
     */
    function addPositiveFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        string _type,
        int _pointsGained,
        address _reporterPlasma,
        address _campaignAddress
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

        emit FeedbackSubmitted(
            _plasmaAddress,
            _role,
            _type,
            _pointsGained,
            _reporterPlasma,
            _campaignAddress
        );
    }


    /**
     * @notice          Function to add negative feedback for user from maintainer
     * @param           _plasmaAddress is user plasma address
     * @param           _role is representing as which role user received this feedback
     * @param           _type is representing mostly if the feedback was for monetary/budget campaigns
     * @param           _pointsLost is amount of points lost because of this feedback
     * @param           _reporterPlasma is address of user who submitted this feedback
     * @param           _campaignAddress is address of campaign for which user submitted feedback
     */
    function addNegativeFeedbackByMaintainer(
        address _plasmaAddress,
        string _role,
        string _type,
        int _pointsLost,
        address _reporterPlasma,
        address _campaignAddress
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

        emit FeedbackSubmitted(
            _plasmaAddress,
            _role,
            _type,
            _pointsLost*(-1),
            _reporterPlasma,
            _campaignAddress
        );
    }


    /**
     * @notice          Function to update reputation points for executed conversions
     *                  in Budget campaigns.
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
        updateReputationPointsForExecutedConversionInternal(
            converter,
            contractor,
            initialRewardWei,
            "BUDGET"
        );
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
        updateReputationPointsForRejectedConversionsInternal(
            converter,
            contractor,
            initialPunishmentWei,
            "BUDGET"
        );
    }


    /**
     * @notice          Function to update user reputations score on signup action
     * @param           _plasmaAddress is user plasma address
     */
    function updateUserReputationScoreOnSignup(
        address _plasmaAddress
    )
    public
    {
        // Only TwoKeyPlasmaRegistry can call this method.
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry"));

        int signupReward = 5 * (10**18);

        bytes32 keyHash = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        // Require that this address haven't already got signup points allocated
        require(PROXY_STORAGE_CONTRACT.getInt(keyHash) == 0);

        // Allocate signup reward points for user.
        PROXY_STORAGE_CONTRACT.setInt(
            keyHash,
            signupReward
        );

        // Emit event
        emit ReputationUpdated(
            _plasmaAddress,
            "",
            "SIGNUP",
            signupReward,
            address(0)
        );
    }


    /**
     * @notice          Function to get reputation and feedback score in case he's an influencer & converter
     * @param           _plasmaAddress is plasma address of user
     */
    function getReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int,int,int,int,int)
    {
        int converterReputationScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2converterGlobalReputationScoreWei, _plasmaAddress)
        );

        int referrerReputationScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, _plasmaAddress)
        );

        int converterFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONVERTER")
        );

        int referrerFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(
            keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "REFERRER")
        );

        return (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore,
            getUserSignupScore(_plasmaAddress)
        );
    }


    /**
     * @notice          Function to get global reputation for specific user
     * @param           _plasmaAddress is plasma address for user
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
        int signupScore;

        (
            converterReputationScore,
            referrerReputationScore,
            converterFeedbackScore,
            referrerFeedbackScore,
            signupScore
        ) = getReputationForUser(_plasmaAddress);

        return (converterReputationScore + referrerReputationScore + converterFeedbackScore + referrerFeedbackScore + signupScore);
    }


    /**
     * @notice          Function to get reputation and feedback score in
     *                  case he's a business page (contractor)
     * @param           _plasmaAddress is plasma address of user
     */
    function getReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int,int,int)
    {
        bytes32 keyHashContractorScore = keccak256(_plasmaAddress2contractorGlobalReputationScoreWei, _plasmaAddress);
        int contractorReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        bytes32 keyHashPlasmaAddressToFeedbackAsContractor = keccak256(_plasmaAddress2Role2Feedback, _plasmaAddress, "CONTRACTOR");
        int contractorFeedbackScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToFeedbackAsContractor);

        bytes32 keyHashPlasmaAddressToSignupScore = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        int contractorSignupScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToSignupScore);

        return (
            contractorReputationScore,
            contractorFeedbackScore,
            contractorSignupScore
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
        int contractorSignupScore;

        (contractorReputationScore,contractorFeedbackScore,contractorSignupScore) =
            getReputationForContractor(_plasmaAddress);

        return (contractorReputationScore + contractorFeedbackScore + contractorSignupScore);
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


    /**
     * @notice          Function to check user signup score
     * @param           _plasmaAddress is user plasma address
     * @return          reputation points user earned for signup action.
     */
    function getUserSignupScore(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        bytes32 keyHashPlasmaAddressToSignupScore = keccak256(_plasmaAddress2signupBonus, _plasmaAddress);
        int signupScore = PROXY_STORAGE_CONTRACT.getInt(keyHashPlasmaAddressToSignupScore);
        return signupScore;
    }
}
