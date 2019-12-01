pragma solidity ^0.4.24;

import "./TwoKeyCampaignAbstract.sol";
import "../interfaces/ITwoKeyPlasmaRegistry.sol";

contract TwoKeyPlasmaCampaign is TwoKeyCampaignAbstract {

    ITwoKeyPlasmaRegistry public twoKeyPlasmaRegistry;

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
    returns (bool)
    {
        // _from and _to are assumed to be already converted to plasma address (e.g. using plasmaOf)
        require(_value == 1);
        require(balances[_from] > 0);

        balances[_from] = balances[_from].sub(1);
        balances[_to] = balances[_to].add(conversionQuota);
        totalSupply_ = totalSupply_.add(conversionQuota.sub(1));

        received_from[_to] = _from;
        return true;
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
     * @notice Function to set cut of
     * @param me is the address (plasma)
     * @param cut is the cut value
     */
    function setCutOf(
        address me,
        uint256 cut
    )
    internal
    {
        require(referrerPlasma2cut[me] == 0 || referrerPlasma2cut[me] == cut);
        referrerPlasma2cut[me] = cut;
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
        uint8[] memory weights;
        address old_address;
        (influencers, keys, weights, old_address) = getInfluencersKeysAndWeightsFromSignature(sig, _converter);
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

            if (i < weights.length) {
                setCutOf(new_address, uint256(weights[i]));
            }
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
        uint numberOfInfluencers = 0;
        if(received_from[_converter] == address(0)) {
            numberOfInfluencers = distributeArcsBasedOnSignature(signature, _converter);
        }
        return numberOfInfluencers;
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

    /**
     * @notice Function to get cut for an (ethereum) address
     * @param me is the ethereum address
     */
    function getReferrerCut(
        address me
    )
    public
    view
    returns (uint256)
    {
        return referrerPlasma2cut[me];
    }

}
