pragma solidity ^0.4.24;

import "./ArcToken.sol";
import "../libraries/Call.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";

contract TwoKeyCampaignAbstract is ArcToken {

    using SafeMath for uint256;
    using Call for *;

    bool isCampaignInitialized; // Representing if campaign "constructor" was called

    address public TWO_KEY_SINGLETON_REGISTRY;

    uint256 maxReferralRewardPercent; // maxReferralRewardPercent is actually bonus percentage in ETH

    address public contractor; //contractor address
    address public moderator; //moderator address

    uint256 conversionQuota;  // maximal ARC tokens that can be passed in transferFrom
    uint256 reservedAmount2keyForRewards; //Reserved amount of 2key tokens for rewards distribution

    string public publicMetaHash; // Ipfs hash of json campaign object
    string public privateMetaHash; // Ipfs hash of json sensitive (contractor) information

    mapping(address => uint256) internal referrerPlasma2Balances2key; // balance of EthWei for each influencer that he can withdraw

    mapping(address => address) internal public_link_key;
    mapping(address => address) internal received_from; // referral graph, who did you receive the referral from


    // @notice Modifier which allows only contractor to call methods
    modifier onlyContractor() {
        require(msg.sender == contractor);
        _;
    }

    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

    /**
     * @notice Function to set or update public meta hash
     * @param _publicMetaHash is the hash of the campaign
     * @dev Only contractor can call this
     */
    function startCampaignWithInitialParams(
        string _publicMetaHash,
        string _privateMetaHash,
        address _publicKey
    )
    public
    onlyContractor
    {
        publicMetaHash = _publicMetaHash;
        privateMetaHash = _privateMetaHash;
        setPublicLinkKeyOf(msg.sender, _publicKey);
    }


    /**
     * @notice Function to allow updating public meta hash
     * @param _newPublicMetaHash is the new meta hash
     */
    function updateIpfsHashOfCampaign(
        string _newPublicMetaHash
    )
    public
    onlyContractor
    {
        publicMetaHash = _newPublicMetaHash;
    }



    function setPublicLinkKeyOf(
        address me,
        address new_public_key
    )
    internal;

    /**
     * @notice Getter for the referral chain
     * @param _receiver is address we want to check who he has received link from
     */
    function getReceivedFrom(
        address _receiver
    )
    public
    view
    returns (address)
    {
        return received_from[_receiver];
    }



}
