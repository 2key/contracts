pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.sol";
import "../interfaces/ITwoKeyPlasmaFactory.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyPlasmaAffiliationCampaign.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";

import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

/**
 * TwoKeyPlasmaAffiliationCampaignsPaymentsHandler contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyPlasmaAffiliationCampaignsPaymentsHandler is Upgradeable {

    using SafeMath for *;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    // Mapping referrer to all campaigns he ever had rewards in
    string constant _referrerToCampaigns = "referrerToCampaigns";
    string constant _referrerToIsCampaignAlreadyAddedToArray = "referrerToIsCampaignAlreadyAddedToArray";
    string constant _isSignatureExisting = "isSignatureExisting";

    ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage(_proxyStorage);

        initialized = true;
    }


    modifier onlyMaintainer {
        require(
            ITwoKeyMaintainersRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry"))
                .checkIsAddressMaintainer(msg.sender) == true
        );
        _;
    }

    modifier onlyAffiliationCampaign {
        string memory campaignType = ITwoKeyPlasmaFactory(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaFactory"))
            .addressToCampaignType(msg.sender);
        require(
            keccak256(campaignType) == keccak256("AFFILIATION_PLASMA")
        );
        _;
    }
    /*
     ************************************************************************************
     *                      INTERNAL FUNCTIONS
     ************************************************************************************
     */


    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key,value);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getAddressArray(
        bytes32 key
    )
    internal
    view
    returns (address[])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }

    function setAddressArray(
        bytes32 key,
        address [] addresses
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddressArray(key, addresses);
    }

    /**
     * @notice          Function to add campaign address to list of referrer campaigns
     * @param           referrer is the referrer address
     * @param           campaign is the address of campaign
     */
    function addCampaignForReferrer(
        address referrer,
        address campaign
    )
    internal
    {
        address [] memory referrerCampaigns = getCampaignsForReferrer(referrer);

        address [] memory newReferrerCampaigns = new address[](referrerCampaigns.length + 1);

        uint i;

        // Copy existing campaigns to new array
        for(i = 0; i < referrerCampaigns.length; i++) {
            newReferrerCampaigns[i] = referrerCampaigns[i];
        }

        // Add newest campaign to the end
        newReferrerCampaigns[i] = campaign;
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

    /*
     ************************************************************************************
     *                      PUBLIC GETTERS
     ************************************************************************************
    */


    /**
     * @notice          Function to check if campaign is added to list of referrer campaigns
     * @param           campaign is the address of the campaign
     * @param           referrer is the address of referrer
     */
    function isCampaignAddedToReferrerList(
        address campaign,
        address referrer
    )
    public
    view
    returns (bool)
    {
        return getBool(
            keccak256(_referrerToIsCampaignAlreadyAddedToArray, referrer, campaign)
        );
    }


    /**
     * @notice          Function to get campaigns for referrer
     * @param           referrer is the referrer address
     */
    function getCampaignsForReferrer(
        address referrer
    )
    public
    view
    returns (address[])
    {
        return getAddressArray(keccak256(_referrerToCampaigns,referrer));
    }


    /**
     * @notice          Function to get pending rewards on all affiliation campaigns for referrer
     * @param           referrerPlasma is the address of referrer
     * @param           campaigns is the array of supported campaigns
     */
    function getPendingRewardsOnCampaignsForReferrer(
        address referrerPlasma,
        address [] campaigns
    )
    public
    view
    returns (uint[])
    {
        uint [] memory rewards = new uint[](campaigns.length);
        uint i = 0;
        for(i = 0; i < campaigns.length; i++) {
            rewards[i] = ITwoKeyPlasmaAffiliationCampaign(campaigns[i]).getReferrerPlasmaBalance(referrerPlasma);
        }
        return rewards;
    }


    /**
     * @notice          Function to check if signature is existing
     * @param           signature is the signature being checked
     */
    function getIfSignatureIsExisting(
        bytes signature
    )
    public
    view
    returns (bool)
    {
        return getBool(keccak256(_isSignatureExisting, signature));
    }


    function recoverSignature(
        bytes signature,
        address referrerPublic,
        address [] campaigns,
        uint [] rewards
    )
    public
    pure
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(referrerPublic)),
                keccak256(abi.encodePacked(campaigns,rewards))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }


    /**
     * @notice          Function to add campaign to list of referrers campaigns
     * @param           referrerPlasma is the address of referrer
     */
    function addCampaignToListOfReferrerCampaigns(
        address referrerPlasma
    )
    public
    onlyAffiliationCampaign
    {
        address campaign = msg.sender;
        if(!isCampaignAddedToReferrerList(referrerPlasma, campaign)) {
            // Mark that campaign is added to the list
            setBool(
                keccak256(_referrerToIsCampaignAlreadyAddedToArray, referrerPlasma, campaign),
                true
            );
            // Add this campaign to list of referrer campaigns
            addCampaignForReferrer(referrerPlasma,campaign);
        }
    }


    function submitSignatureForUserWithdrawal(
        address referrerPublicAddress,
        address [] campaigns,
        uint [] rewardsPerCampaign,
        bytes signature
    )
    public
    onlyMaintainer
    {
        // Require this function to be called only once with same signature
        require(getIfSignatureIsExisting(signature) == false);

        address referrerPlasma = ITwoKeyPlasmaRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry")).ethereum2plasma(referrerPublicAddress);
        // Require that user is registered
        require(referrerPlasma != address(0));

        // Recover signature with public address
        address messageSigner = recoverSignature(
            signature,
            referrerPublicAddress,
            campaigns,
            rewardsPerCampaign
        );

        // Require that message is signed by signatory address
        require(messageSigner == getSignatoryAddress());

        uint i;

        for(i = 0; i < campaigns.length; i++) {
            // Increase amount withdrawn from campaign
            ITwoKeyPlasmaAffiliationCampaign(campaigns[i]).increaseAmountWithdrawnFromContract(
                referrerPlasma,
                rewardsPerCampaign[i]
            );
        }

        // Set that signature exists
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isSignatureExisting, signature), true);
        // Withdrawal attepmts per user
        // [1,2,3,4]
        // 1 attempt --> signature 1
        //TODO: Account pending withdrawal
        // Store signature for withdrawal
    }

    /**
     * @notice          Function to fetch signatory address
     */
    function getSignatoryAddress()
    public
    view
    returns (address)
    {
        return ITwoKeyPlasmaRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaRegistry")).getSignatoryAddress();
    }
}
