pragma solidity ^0.4.24;


import "../upgradability/Upgradeable.sol";

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyCampaignValidator.sol";
import "../interfaces/storage-contracts/ITwoKeyBaseReputationRegistryStorage.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyBaseReputationRegistry is Upgradeable, ITwoKeySingletonUtils {

    /**
     * Storage keys are stored on the top. Here they are in order to avoid any typos
     */
    string constant _address2contractorGlobalReputationScoreWei = "address2contractorGlobalReputationScoreWei";
    string constant _address2converterGlobalReputationScoreWei = "address2converterGlobalReputationScoreWei";
    string constant _plasmaAddress2referrerGlobalReputationScoreWei = "plasmaAddress2referrerGlobalReputationScoreWei";

    /**
     * Keys for the addresses we're accessing
     */
    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyRegistry = "TwoKeyRegistry";
    bool initialized;

    ITwoKeyBaseReputationRegistryStorage public PROXY_STORAGE_CONTRACT;


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

    /**
     * @notice Since using singletone pattern, this is replacement for the constructor
     * @param _twoKeySingletoneRegistry is the address of registry of all singleton contracts
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBaseReputationRegistryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice Modifier to validate that the call is coming from validated campaign
     */
    modifier isCodeValid() {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    /**
     * @notice If the conversion executed event occured, 10 points for the converter and contractor + 10/distance to referrer
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param campaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionExecutedEvent(
        address converter,
        address contractor,
        address campaign
    )
    public
    isCodeValid
    {
        int initialRewardWei = 10*(10**18);

        updateContractorScore(contractor, initialRewardWei);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + initialRewardWei);

        emit ReputationUpdated(
            plasmaOf(converter),
            "CONVERTER",
            "MONETARY",
            initialRewardWei,
            msg.sender
        );

        address[] memory referrers = getReferrers(converter, campaign);

        int j=0;
        int len = int(referrers.length) - 1;
        for(int i=len; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "MONETARY",
                reward,
                msg.sender
            );

            j++;
        }
    }

    /**
     * @notice If the conversion rejected event occured, giving penalty points
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param campaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionRejectedEvent(
        address converter,
        address contractor,
        address campaign
    )
    public
    isCodeValid
    {
        int initialRewardWei = 5*(10**18);

        updateContractorScoreOnRejectedConversion(contractor, initialRewardWei);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore - initialRewardWei);

        emit ReputationUpdated(
            plasmaOf(converter),
            "CONVERTER",
            "MONETARY",
            initialRewardWei * (-1),
            msg.sender
        );

        address[] memory referrers = getReferrers(converter, campaign);

        int j=0;
        for(int i=int(referrers.length)-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "MONETARY",
                reward*(-1),
                msg.sender
            );
            j++;
        }
    }

    function updateContractorScoreOnRejectedConversion(
        address contractor,
        int reward
    )
    internal
    {
        updateContractorScore(contractor, reward*(-1));
    }

    function updateContractorScore(
        address contractor,
        int reward
    )
    internal
    {
        bytes32 keyHashContractorScore = keccak256(_address2contractorGlobalReputationScoreWei, contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + reward);

        emit ReputationUpdated(
            plasmaOf(contractor),
            "CONTRACTOR",
            "MONETARY",
            reward,
            msg.sender
        );
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch logic handler address
     */
    function getLogicHandlerAddress(
        address campaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyCampaign(campaign).logicHandler();
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch conersion handler address
     */
    function getConversionHandlerAddress(
        address campaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyCampaign(campaign).conversionHandler();
    }


    /**
     * @notice Function to get all referrers in the chain for specific converter
     * @param converter is the converter we want to get referral chain
     * @param campaign is the acquisition campaign contract
     * @return array of addresses (referrers)
     */
    function getReferrers(
        address converter,
        address campaign
    )
    internal
    view
    returns (address[])
    {
        address logicHandlerAddress = getLogicHandlerAddress(campaign);
        return ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter);
    }


    /**
     * @notice          Function to get reputation for user in case he's an influencer or converter
     */
    function getReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int,int)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress(_twoKeyRegistry);
        address ethereumAddress = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_plasmaAddress);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, ethereumAddress);
        int converterReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);

        bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, _plasmaAddress);
        int referrerReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);

        return (converterReputationScore, referrerReputationScore);
    }

    function getGlobalReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int converterReputationScore;
        int referrerReputationScore;

        (converterReputationScore, referrerReputationScore) = getReputationForUser(_plasmaAddress);

        return (converterReputationScore + referrerReputationScore);
    }


    function getGlobalReputationForUsers(
        address [] plasmaAddresses
    )
    public
    view
    returns (int[])
    {
        uint len = plasmaAddresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForUser(plasmaAddresses[i]);
        }

        return (reputations);
    }

    /**
     * @notice          Function to get reputation for user in case he's contractor
     */
    function getReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress(_twoKeyRegistry);
        address ethereumAddress = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_plasmaAddress);

        bytes32 keyHashContractorScore = keccak256(_address2contractorGlobalReputationScoreWei, ethereumAddress);
        int contractorReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        return (contractorReputationScore);
    }


    function getGlobalReputationForContractors(
        address [] plasmaAddresses
    )
    public
    view
    returns (int[])
    {
        uint len = plasmaAddresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getReputationForContractor(plasmaAddresses[i]);
        }

        return (reputations);
    }

    function plasmaOf(
        address _address
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyReg(getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry)).getEthereumToPlasma(_address);
    }
}
