pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaEventSourceStorage.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";


/**
 * @title Contract which is used to emit events on sidechain
 * @author Nikola Madjarevic (Github : @madjarevicn)
 */
contract TwoKeyPlasmaEventSource is Upgradeable {

    bool initialized;

    ITwoKeyPlasmaEventSourceStorage public PROXY_STORAGE_CONTRACT;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    string constant _twoKeyPlasmaRegistry = "TwoKeyPlasmaRegistry";
    string constant _twoKeyPlasmaFactory = "TwoKeyPlasmaFactory";
    string constant _twoKeyPlasmaBudgetCampaignsPaymentsHandler = "TwoKeyPlasmaBudgetCampaignsPaymentsHandler";


    /**
     * @notice          Function which is replication for constructor
     *                  and can be called only once in a lifetime
     *
     * @param           _twoKeyPlasmaSingletonRegistry is the address of plasma singleton registry
     * @param           _proxyStorage is the proxy address of storage contract
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaEventSourceStorage(_proxyStorage);

        initialized = true;
    }


    event Plasma2Ethereum(
        address plasma,
        address eth
    );


    event Plasma2Handle(
        address plasma,
        string handle
    );


    event ConversionCreated(
        address campaignAddressPlasma,
        address campaignAddressPublic,
        uint conversionID,
        address contractor,
        address converter
    );


    event ConversionExecuted(
        address campaignAddressPlasma,
        uint conversionID
    );


    event ConversionPaid(
        address campaignAddressPlasma,
        uint conversionID
    );


    event ConversionRejected(
        address campaignAddressPlasma,
        uint conversionID,
        uint statusCode
    );


    event CPCCampaignCreated(
        address proxyCPCCampaignPlasma,
        address contractorPlasma
    );


    event PlasmaMirrorCampaigns(
        address proxyPlasmaAddress,
        address proxyPublicAddress
    );


    event AddedPendingRewards(
        address contractAddress,
        address influencer,
        uint rewards
    );

    event PaidPendingRewards(
        address influencer,
        uint nonRebalancedRewards,
        uint rewards,
        address [] campaignsPaid,
        uint [] earningsPerCampaign,
        uint feePerReferrer2KEY
    );


    event HandleChanged(
        address userPlasmaAddress,
        string newHandle
    );


    event RewardsAssignedToUserInParticipationMiningEpoch(
        uint epochId,
        address user,
        uint reward2KeyWei
    );


    event EpochDeclared(
        uint epochId,
        uint totalRewardsInEpoch
    );


    event EpochRegistered(
        uint epochId,
        uint numberOfUsers
    );


    event EpochFinalized(
        uint epochId
    );


    modifier onlyTwoKeyPlasmaFactory {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(msg.sender == twoKeyPlasmaFactory);
        _;
    }


    modifier onlyWhitelistedCampaigns {
        address twoKeyPlasmaFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaFactory);
        require(ITwoKeyPlasmaFactory(twoKeyPlasmaFactory).isCampaignCreatedThroughFactory(msg.sender) == true);
        _;
    }


    modifier onlyTwoKeyPlasmaRegistry {
        address twoKeyPlasmaRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaRegistry);
        require(msg.sender == twoKeyPlasmaRegistry);
        _;
    }


    modifier onlyTwoKeyPlasmaBudgetCampaignsPaymentsHandler {
        address twoKeyPlasmaBudgetCampaignsPaymentsHandler = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaBudgetCampaignsPaymentsHandler);
        require(msg.sender == twoKeyPlasmaBudgetCampaignsPaymentsHandler);
        _;
    }


    /**
     * @notice          Function to return proxy address of the contract registered
     *                  in TwoKeyPlasmaSingletonRegistry contract
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }


    /**
     * @notice          Function that emits an event when conversion is created
     *
     * @param           campaignAddressPublic is the public address of the campaign
     * @param           conversionID is the ID of the conversion
     * @param           contractor is the contractor plasma address
     * @param           converter is the converter plasma address
     *
     * @dev             Can be only called by whitelisted campaigns
     */
    function emitConversionCreatedEvent(
        address campaignAddressPublic,
        uint conversionID,
        address contractor,
        address converter
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionCreated(
            msg.sender,
            campaignAddressPublic,
            conversionID,
            contractor,
            converter
        );
    }


    /**
     * @notice          Function to emit event when conversion is executed
     *
     * @param           conversionID is the ID of the conversion being executed
     */
    function emitConversionExecutedEvent(
        uint conversionID
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionExecuted(
            msg.sender,
            conversionID
        );
    }


    /**
     * @notice          Function to emit event that conversion is being paid
     *
     * @param           conversionID is the ID of conversion being executed
     */
    function emitConversionPaidEvent(
        uint conversionID
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionPaid(msg.sender, conversionID);
    }


    /**
     * @notice          Function to emit event when conversion is rejected
     *
     * @param           conversionID is the ID of the conversion being rejected
     * @param           statusCode is the code which is mapping to reason of rejection
     */
    function emitConversionRejectedEvent(
        uint conversionID,
        uint statusCode
    )
    public
    onlyWhitelistedCampaigns
    {
        emit ConversionRejected(
            msg.sender,
            conversionID,
            statusCode
        );
    }


    /**
     * @notice          Function to emit an event when CPC campaign is being created
     *
     * @param           proxyCPCCampaignPlasma is the proxy address for CPC campaign on plasma network
     * @param           contractorPlasma is contractor plasma address
     */
    function emitCPCCampaignCreatedEvent(
        address proxyCPCCampaignPlasma,
        address contractorPlasma
    )
    public
    onlyTwoKeyPlasmaFactory
    {
        emit CPCCampaignCreated(
            proxyCPCCampaignPlasma,
            contractorPlasma
        );
    }


    /**
     * @notice          Function to emit an event when CPC campaign is validated
     *
     * @param           proxyAddressPlasma is the plasma address of the campaign
     * @param           proxyAddressPublic is the public address of the campaign
     */
    function emitCPCCampaignMirrored(
        address proxyAddressPlasma,
        address proxyAddressPublic
    )
    public
    onlyWhitelistedCampaigns
    {
        emit PlasmaMirrorCampaigns(
            proxyAddressPlasma,
            proxyAddressPublic
        );
    }


    /**
     * @notice          Function to emit event when plasma is linked to ethereum address
     *
     * @param           _plasma is the plasma address which is being linked
     * @param           _ethereum is the ethereum address which is being linked
     */
    function emitPlasma2EthereumEvent(
        address _plasma,
        address _ethereum
    )
    public
    onlyTwoKeyPlasmaRegistry
    {

        emit Plasma2Ethereum(_plasma, _ethereum);
    }


    /**
     * @notice          Function to emit event when plasma is linked to user handle
     *
     * @param           _plasma is the plasma address which is being linked
     * @param           _handle is the users handle to which we're linking plasma
     */
    function emitPlasma2HandleEvent(
        address _plasma,
        string _handle
    )
    public
    onlyTwoKeyPlasmaRegistry
    {
        emit Plasma2Handle(_plasma, _handle);
    }


    /**
     * @notice          Function to emit event when user changes his handle
     *
     * @param           _userPlasmaAddress is the users plasma address
     * @param           _newHandle is the new username user wants to set
     */
    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public
    onlyTwoKeyPlasmaRegistry
    {
        emit HandleChanged(
            _userPlasmaAddress,
            _newHandle
        );
    }


    /**
     * @notice          Function to emit ane vent when rewards are added but not paid
     * @param           campaignPlasma is campaign address for which user received rewards
     * @param           influencer address of user
     * @param           amountOfTokens is the amount of tokens for user.
     */
    function emitAddedPendingRewards(
        address campaignPlasma,
        address influencer,
        uint amountOfTokens
    )
    public
    onlyTwoKeyPlasmaBudgetCampaignsPaymentsHandler
    {
        emit AddedPendingRewards(
            campaignPlasma,
            influencer,
            amountOfTokens
        );
    }


    /**
     * @notice          Function to emit an event when pending rewards accumulated from budget campaigns
     *                  are being paid to the user
     * @param           influencer is the user address
     * @param           amountNonRebalancedEarned is amount of tokens user earned, but prior to rebalancing
     * @param           amountPaid is actual amount user received, after rebalancing is done
     * @param           campaignsPaid is an array of campaigns for which user received rewards
     * @param           earningsPerCampaign is how much user earned per each campaign
     * @param           feePerReferrer2KEY is withdrawal fee for which user is charged
     */
    function emitPaidPendingRewards(
        address influencer,
        uint amountNonRebalancedEarned,
        uint amountPaid,
        address [] campaignsPaid,
        uint [] earningsPerCampaign,
        uint feePerReferrer2KEY
    )
    public
    onlyTwoKeyPlasmaBudgetCampaignsPaymentsHandler
    {
        emit PaidPendingRewards(
            influencer,
            amountNonRebalancedEarned,
            amountPaid,
            campaignsPaid,
            earningsPerCampaign,
            feePerReferrer2KEY
        );
    }


    /**
     * @notice          Function to emit an event whenever there are rewards assigned to user in
     *                  participation mining epoch
     * @param           epochId is the ID of the epoch
     * @param           user is the address of user being rewarded
     * @param           reward2KeyWei is reward in 2KEY tokens
     */
    function emitRewardsAssignedToUserInParticipationMiningEpoch(
        uint epochId,
        address user,
        uint reward2KeyWei
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaParticipationRewards"));

        emit RewardsAssignedToUserInParticipationMiningEpoch(
            epochId,
            user,
            reward2KeyWei
        );
    }


    /**
     * @notice          Function to emit event whenever there's new epoch declared
     * @param           epochId is the ID of that epoch
     * @param           totalRewardsInEpoch is the amount of tokens to be distributed in that epoch
     */
    function emitEpochDeclared(
        uint epochId,
        uint totalRewardsInEpoch
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaParticipationRewards"));

        emit EpochDeclared(
            epochId,
            totalRewardsInEpoch
        );
    }


    /**
     * @notice          Function to emit event whenever there's new epoch registered
     * @param           epochId is the ID of that epoch
     * @param           numberOfUsers is number of users to be rewarded in that epoch
     */
    function emitEpochRegistered(
        uint epochId,
        uint numberOfUsers
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaParticipationRewards"));

        emit EpochRegistered(
            epochId,
            numberOfUsers
        );
    }


    /**
     * @notice          Function to emit event when there's epoch finalized
     * @param           epochId is the ID of that epoch
     */
    function emitEpochFinalized(
        uint epochId
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaParticipationRewards"));

        emit EpochFinalized(
            epochId
        );
    }
}
