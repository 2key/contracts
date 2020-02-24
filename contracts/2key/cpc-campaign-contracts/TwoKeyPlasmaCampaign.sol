pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignAbstract.sol";


contract TwoKeyPlasmaCampaign is TwoKeyCampaignIncentiveModels, TwoKeyCampaignAbstract {

    IncentiveModel incentiveModel; //Incentive model for rewards

    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;

    address public contractorPublicAddress; // Contractor address on public chain

    uint public moderatorTotalEarnings; // total rewards which are going to moderator

    uint campaignStartTime; // Time when campaign start
    uint campaignEndTime; // Time when campaign ends

    // Representing number of influencers between contractor and converter
    mapping(address => uint) public converterToNumberOfInfluencers;

    // Validator if campaign is validated from maintainer side
    bool public isValidated;

    // Modifier restricting calls only to maintainers
    modifier onlyMaintainer {
        require(isMaintainer(msg.sender));
        _;
    }

    // Checking if the campaign is created through TwoKeyPlasmaFactory
    modifier isCampaignValidated {
        require(isValidated == true);
        _;
    }


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from ALREADY converted to plasma
     * @param _to address The address which you want to transfer to ALREADY converted to plasma
     * @param _value uint256 the amount of tokens to be transferred
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
     * @notice Private function to set public link key to plasma address
     * @param me is the plasma address
     * @param new_public_key is the new key user want's to set as his public key
     */
    function setPublicLinkKeyOf(
        address me,
        address new_public_key
    )
    internal
    {
        require(balanceOf(me) > 0);
        address old_address = public_link_key[me];
        if (old_address == address(0)) {
            public_link_key[me] = new_public_key;
        } else {
            require(old_address == new_public_key);
        }
        public_link_key[me] = new_public_key;
    }


    /**
      * @notice Function which will unpack signature and get referrers, keys, and weights from it
      * @param sig is signature
      */
    function getInfluencersKeysAndWeightsFromSignature(
        bytes sig,
        address _converter
    )
    internal
    view
    returns (address[],address[],uint8[],address)
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
        uint8[] memory weights;
        (influencers, keys, weights) = Call.recoverSig(sig, old_key, _converter);

        require(
            influencers[influencers.length-1] == _converter
        );

        return (influencers, keys, weights, old_address);
    }


    /**
     * @notice Function to track arcs and make ref tree
     * @param sig is the signature user joins from
     */
    function distributeArcsBasedOnSignature(
        bytes sig,
        address _converter
    )
    internal
    returns (uint)
    {
        address[] memory influencers;
        address[] memory keys;
        address old_address;
        (influencers, keys,, old_address) = getInfluencersKeysAndWeightsFromSignature(sig, _converter);
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

        if(numberOfInfluencers > 0) {
            return numberOfInfluencers - 1;
        }

        return numberOfInfluencers;
    }


    function distributeArcsIfNecessary(
        address _converter,
        bytes signature
    )
    internal
    returns (uint)
    {
        if(received_from[_converter] == address(0)) {
            converterToNumberOfInfluencers[_converter] = distributeArcsBasedOnSignature(signature, _converter);
        }
        return converterToNumberOfInfluencers[_converter];
    }


    /**
     * @notice Function to get public link key of an address
     * @param me is the address we're checking public link key
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
     * @notice Function to get balance of influencer for his plasma address
     * @param _influencer is the plasma address of influencer
     * @return balance in wei's
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
     * @notice Function to validate that contracts plasma and public are well mirrored
     */
    function validateContractFromMaintainer()
    public
    onlyMaintainer
    {
        isValidated = true;
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


}
