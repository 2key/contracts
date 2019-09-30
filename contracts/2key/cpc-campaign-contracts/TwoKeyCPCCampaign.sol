pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../libraries/Call.sol";
import "../../openzeppelin-solidity/contracts/MerkleProof.sol";
import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";

import "../interfaces/ITwoKeyDonationConversionHandler.sol";
import "../interfaces/ITwoKeyDonationLogicHandler.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyCPCCampaign is UpgradeableCampaign, TwoKeyCampaign, TwoKeyCampaignIncentiveModels {

    bool initialized;

    address public twoKeyDonationConversionHandler; // Contract which will handle all donations
    address public twoKeyDonationLogicHandler;
    address public mirrorCampaign;

    address[] public activeInfluencers;
    bytes32 public merkle_root;

    // @notice Modifier which allows only moderator to call methods
    // TODO should be in TwoKeyCampaign.sol
    modifier onlyModerator() {
        require(msg.sender == moderator);
        _;
    }

    bool acceptsFiat; // Will determine if fiat conversion can be created or not

    event ConvertSig(address indexed influencer, bytes signature, address plasmaConverter, bytes moderatorSig);
    string public website;

    //Referral accounting stuff
    mapping(address => uint256) private referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address

    modifier onlyTwoKeyDonationConversionHandler {
        require(msg.sender == twoKeyDonationConversionHandler);
        _;
    }

    function setMirrorCampaign(address _mirrorCampaign) {
        require(mirrorCampaign == address(0),'cpc6');

        mirrorCampaign = _mirrorCampaign;
    }

    function setWebsiteCPCCampaign(
        string _website
    )
    public
    {
        require(initialized == false,'cpc7');
        website = _website;
    }

    function setInitialParamsCPCCampaign(
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
        address _twoKeyDonationConversionHandler,
        address _twoKeyDonationLogicHandler,
        uint [] numberValues,
        bool [] booleanValues
    )
    public
    {
        require(initialized == false);

        contractor = _contractor;
        // Moderator address
        moderator = _moderator;

        twoKeySingletonesRegistry = _twoKeySingletonRegistry;
        twoKeyEventSource = TwoKeyEventSource(getContractProxyAddress("TwoKeyEventSource"));
        twoKeyEconomy = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry)
            .getNonUpgradableContractAddress("TwoKeyEconomy");
        totalSupply_ = 1000000;

        maxReferralRewardPercent = numberValues[0];
        conversionQuota = numberValues[6];

        twoKeyDonationConversionHandler = _twoKeyDonationConversionHandler;
        twoKeyDonationLogicHandler = _twoKeyDonationLogicHandler;


//        mustConvertToReferr = booleanValues[0];
        isKYCRequired = booleanValues[1];
        acceptsFiat = booleanValues[2];


        ownerPlasma = twoKeyEventSource.plasmaOf(_contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;


        initialized = true;
    }

    /**
      * @notice Function to set cut of
      * @param me is the address (ethereum)
      * @param cut is the cut value
      */
    function setCutOf(
        address me,
        uint256 cut
    )
    internal
    {
        // what is the percentage of the bounty s/he will receive when acting as an influencer
        // the value 255 is used to signal equal partition with other influencers
        // A sender can set the value only once in a contract
        address plasma = twoKeyEventSource.plasmaOf(me);
        require(referrerPlasma2cut[plasma] == 0 || referrerPlasma2cut[plasma] == cut);
        referrerPlasma2cut[plasma] = cut;
    }

    /**
     * @notice Function to set cut
     * @param cut is the cut value
     * @dev Executes internal setCutOf method
     */
    function setCut(
        uint256 cut
    )
    public
    {
        setCutOf(msg.sender, cut);
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
        return referrerPlasma2cut[twoKeyEventSource.plasmaOf(me)];
    }

    /**
     * @notice Function to track arcs and make ref tree
     * @param sig is the signature user joins from
     */
    function distributeArcsBasedOnSignature(
        bytes sig,
        address _converter
    )
    private
    returns (address[])
    {
        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        address old_address;
        (influencers, keys, weights, old_address) = super.getInfluencersKeysAndWeightsFromSignature(sig, _converter);
        uint i;
        address new_address;
        uint numberOfInfluencers = influencers.length;
        for (i = 0; i < numberOfInfluencers; i++) {
            new_address = twoKeyEventSource.plasmaOf(influencers[i]);

            if (received_from[new_address] == 0) {
                transferFrom(old_address, new_address, 1);
            } else {
                require(received_from[new_address] == old_address,'only tree ARCs allowed');
            }
            old_address = new_address;

            // TODO Updating the public key of influencers may not be a good idea because it will require the influencers to use
            // a deterministic private/public key in the link and this might require user interaction (MetaMask signature)
            // TODO a possible solution is change public_link_key to address=>address[]
            // update (only once) the public address used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < keys.length) {
                setPublicLinkKeyOf(new_address, keys[i]);
            }

            // update (only once) the cut used by each influencer
            // we will need this in case one of the influencers will want to start his own off-chain link
            if (i < weights.length) {
                setCutOf(new_address, uint256(weights[i]));
            }
        }
        return influencers;
    }


    /**
     * @notice Option to update contractor proceeds
     * @dev can be called only from TwoKeyConversionHandler contract
     * @param value it the value we'd like to add to total contractor proceeds and contractor balance
     */
    function updateContractorProceeds(
        uint value
    )
    public
    {
        require(msg.sender == twoKeyDonationConversionHandler);
        contractorTotalProceeds = contractorTotalProceeds.add(value);
        contractorBalance = contractorBalance.add(value);
    }

    /**
     * @notice Function to join with signature and share 1 arc to the receiver
     * @param signature is the signature
     * @param receiver is the address we're sending ARCs to
     */
    function joinAndShareARC(
        bytes signature,
        address receiver
    )
    public
    {
        distributeArcsBasedOnSignature(signature, msg.sender);
        transferFrom(twoKeyEventSource.plasmaOf(msg.sender), twoKeyEventSource.plasmaOf(receiver), 1);
    }

    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convertConverterValue(
        bytes signature, address converter, uint value
    )
    private
    returns (address[])
    {
        bool canConvert = ITwoKeyDonationLogicHandler(twoKeyDonationLogicHandler).checkAllRequirementsForConversionAndTotalRaised(
            converter,
            value
        );
        require(canConvert == true);
        address _converterPlasma = twoKeyEventSource.plasmaOf(converter);
        address[] memory influencers;
        if(received_from[_converterPlasma] == address(0)) {
            influencers = distributeArcsBasedOnSignature(signature, converter);
        }
        createConversion(value, converter);
        return influencers;
    }

//    function convert(
//        bytes signature
//    )
//    public
//    payable
//    {
//        convertConverterValue(signature, msg.sender, msg.value);
//    }

    function convertByModeratorSig(
        bytes signature, bytes converterSig, bytes moderatorSig
    )
    public
//    payable
    {
        // TODO this can only run on plasma
        require(merkle_root == 0, 'merkle root already defined, contract is locked');

        address plasmaConverter = Call.recoverHash(keccak256(signature), converterSig, 0);
        address m = Call.recoverHash(keccak256(abi.encodePacked(signature,converterSig)), moderatorSig, 0);
        require(moderator == m || twoKeyEventSource.plasmaOf(moderator)  == m);
        // TODO use maxDonationAmount instead of 1ETH constant below
        address[] memory influencers = convertConverterValue(signature, plasmaConverter, 100000000000000000); // msg.value  contract donates 1ETH

        // TODO run this only on plasma (to save gas on mainnet)
        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers-1; i++) {
            address influencer = twoKeyEventSource.plasmaOf(influencers[i]);
            emit ConvertSig(influencer, signature, plasmaConverter, moderatorSig);
        }
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     */
    function createConversion(
        uint conversionAmountEthWEI,
        address converterAddress
    )
    private
    {
        uint256 maxReferralRewardFiatOrETHWei = conversionAmountEthWEI.mul(maxReferralRewardPercent).div(100);

        uint conversionId = ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).supportForCreateConversion(
            converterAddress,
            conversionAmountEthWEI,
            maxReferralRewardFiatOrETHWei,
            isKYCRequired
        );

        if(isKYCRequired == false) {
            ITwoKeyDonationConversionHandler(twoKeyDonationConversionHandler).executeConversion(conversionId);
        }
    }

    function getTokenAmountToBeSoldFromUpgradableExchange(
        uint amountOfMoney
    )
    internal
    returns (uint)
    {
        address upgradableExchange = getContractProxyAddress("TwoKeyUpgradableExchange");
        uint amountBought = IUpgradableExchange(upgradableExchange).getTokenAmountToBeSold(amountOfMoney);
        return amountBought;
    }

    /**
      * called by convertByModeratorSig->convertConverterValue->createConversion->twoKeyDonationConversionHandler.executeConversion
      * @notice Function to delegate call to logic handler and update data, and buy tokens
      * @param _maxReferralRewardETHWei total reward in ether wei
      * @param _converter is the converter address
      * @param _conversionId is the ID of conversion
      */
    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint)
    {
        require(msg.sender == twoKeyDonationConversionHandler);
        //Fiat rewards = fiatamount * moderatorPercentage / 100  / 0.095
        uint totalBounty2keys;
        //If fiat conversion do exactly the same just send different reward and don't buy tokens, take them from contract
        if(maxReferralRewardPercent > 0) {
            //estimate how much Buy tokens from upgradable exchange
            totalBounty2keys = getTokenAmountToBeSoldFromUpgradableExchange(_maxReferralRewardETHWei);
            //Handle refchain rewards
            ITwoKeyDonationLogicHandler(twoKeyDonationLogicHandler).updateRefchainRewards(
                _maxReferralRewardETHWei,
                _converter,
                _conversionId,
                totalBounty2keys);
        }
        // TODO comment this?
//        reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalBounty2keys);
        return totalBounty2keys;
    }

    /**
     * @notice Function which will buy tokens from upgradable exchange for moderator
     * @param moderatorFee is the fee in tokens moderator earned
     */
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public
    onlyTwoKeyDonationConversionHandler
    {
        //Get deep freeze token pool address
        address twoKeyDeepFreezeTokenPool = getContractProxyAddress("TwoKeyDeepFreezeTokenPool");

        uint networkFee = twoKeyEventSource.getTwoKeyDefaultNetworkTaxPercent();

        // Balance which will go to moderator
        uint balance = moderatorFee.mul(100-networkFee).div(100);

        uint moderatorEarnings2key = getTokenAmountToBeSoldFromUpgradableExchange(balance); //  tokens for moderator
        getTokenAmountToBeSoldFromUpgradableExchange(moderatorFee - balance); //  tokens for deep freeze token pool

        moderatorTotalEarnings2key = moderatorTotalEarnings2key.add(moderatorEarnings2key);
    }

    /**
     * @notice Function which acts like getter for all cuts in array
     * @param last_influencer is the last influencer
     * @return array of integers containing cuts respectively
     */
    function getReferrerCuts(
        address last_influencer
    )
    public
    view
    returns (uint256[])
    {
        address[] memory influencers = ITwoKeyDonationLogicHandler(twoKeyDonationLogicHandler).getReferrers(last_influencer);
        uint256[] memory cuts = new uint256[](influencers.length + 1);

        uint numberOfInfluencers = influencers.length;
        for (uint i = 0; i < numberOfInfluencers; i++) {
            address influencer = influencers[i];
            cuts[i] = getReferrerCut(influencer);
        }
        cuts[influencers.length] = getReferrerCut(last_influencer);
        return cuts;
    }


    /**
     * @param _referrer we want to check earnings for
     */
    function getReferrerBalance(address _referrer) public view returns (uint) {
        return referrerPlasma2Balances2key[twoKeyEventSource.plasmaOf(_referrer)];
    }

    /**
     * @notice Function to update referrer plasma balance
     * @param _influencer is the plasma address of referrer
     * @param _balance is the new balance
     */
    function updateReferrerPlasmaBalance(
        address _influencer,
        uint _balance
    )
    public
    {
        require(msg.sender == twoKeyDonationLogicHandler);
        if (referrerPlasma2Balances2key[_influencer] != 0) {
            activeInfluencers.push(_influencer);
        }
        referrerPlasma2Balances2key[_influencer] = referrerPlasma2Balances2key[_influencer].add(_balance);
    }

    /**
     * @notice Contractor can withdraw funds only if criteria is satisfied
     */
    function withdrawContractor() public onlyContractor {
        // TODO check this comment:
        // require(ITwoKeyDonationLogicHandler(twoKeyDonationLogicHandler).canContractorWithdrawFunds());
        withdrawContractorInternal();
    }

    /**
     * @notice Function to get reserved amount of rewards
     */
    function getReservedAmount2keyForRewards() public view returns (uint) {
        return reservedAmount2keyForRewards;
    }

    /**
     * @notice Function to send ether back to converter if his conversion is cancelled
     * @param _rejectedConverter is the address of cancelled converter
     * @param _conversionAmount is the amount he sent to the contract
     * @dev This function can be called only by conversion handler
     */
    function sendBackEthWhenConversionRejected(
        address _rejectedConverter,
        uint _conversionAmount
    )
    public
    onlyTwoKeyDonationConversionHandler
    {
        _rejectedConverter.transfer(_conversionAmount);
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
     * @notice set a merkle root of the amount each (active) influencer received.
     *         (active influencer is an influencer that received a bounty)
     *         the idea is that the contractor calls computeMerkleRoot on plasma and then set the value manually
     */
    function setMerkleRoot(
        bytes32 _merkle_root
    )
    public
    onlyModerator
    {
        require(merkle_root == 0, 'merkle root already defined');
        // TODO this can only run in on mainet
        merkle_root = _merkle_root;
    }

    /**
     * @notice compute a merkle root of the amount each (active) influencer received.
     *         (active influencer is an influencer that received a bounty)
     */
    function computeMerkleRoot(
    )
    public
    onlyModerator
    {
        require(merkle_root == 0, 'merkle root already defined');
        // TODO this can only run in on plasma
        // TODO on mainnet the contractor can set this value manually

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            // lock the contract without any influencer
            merkle_root = 1;
            return;
        }

        uint N = 2;
        while (N<numberOfInfluencers) {
            N *= 2;
        }
        bytes32[] memory hashes = new bytes32[](N);
        uint i;
        for (i = 0; i < numberOfInfluencers; i++) {
            address influencer = activeInfluencers[i];
            uint amount = getReferrerPlasmaBalance(influencer);
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }
        while (N>1) {
            for (i = 0; i < N; i+=2) {
                if (hashes[i] < hashes[i+1]) {
                    hashes[i>>1] = keccak256(abi.encodePacked(hashes[i],hashes[i+1]));
                } else {
                    hashes[i>>1] = keccak256(abi.encodePacked(hashes[i+1],hashes[i]));
                }
            }
            N >>= 1;
        }
        merkle_root = hashes[0];
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in the merkle root.
     * @param _influencer the influencer for which we want to get a Merkle proof
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle root,
     *                 which prove that (_influencer,amount) are inside the root.
     */
    function getMerkleProof(
        address _influencer
    )
    public
    view
    returns (bytes32[])
    {
        // TODO this can only run in on plasma
        uint numberOfInfluencers = activeInfluencers.length;
        uint N = 2;
        uint logN = 1;
        while (N<numberOfInfluencers) {
            N *= 2;
            logN++;
        }
        int influencer_idx = -1;
        bytes32[] memory hashes = new bytes32[](N);
        uint i;
        for (i = 0; i < numberOfInfluencers; i++) {
            address influencer = activeInfluencers[i];
            uint amount = getReferrerPlasmaBalance(_influencer);
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
            if (influencer == _influencer) {
                influencer_idx = int(i);
            }
        }
        if (influencer_idx == -1) { // covers also the case when numberOfInfluencers==0 and _influencer==0
            return new bytes32[](0);
        }

        bytes32[] memory proof = new bytes32[](logN);
        logN = 0;
        while (N>1) {
            for (i = 0; i < N; i+=2) {
                if (influencer_idx == int(i)) {
                    proof[logN] = hashes[i+1];
                } else if  (influencer_idx == int(i+1)) {
                    proof[logN] = hashes[i];
                }
                if (hashes[i] < hashes[i+1]) {
                    hashes[i>>1] = keccak256(abi.encodePacked(hashes[i],hashes[i+1]));
                } else {
                    hashes[i>>1] = keccak256(abi.encodePacked(hashes[i+1],hashes[i]));
                }
            }
            influencer_idx >>= 1;
            N >>= 1;
            logN++;
        }
        return proof;
    }

    /**
     * @notice validate a merkle proof.
     */
    function claimMerkleProof(
        bytes32[] proof,
        uint amount
    )
    public
    {
        // TODO check that this is only on mainnet
        require(merkle_root != 0, 'merkle root was not yet set by contractor');
        address influencer = twoKeyEventSource.plasmaOf(msg.sender);
        require(MerkleProof.verifyProof(proof,merkle_root,keccak256(abi.encodePacked(influencer,amount))), 'proof is invalid');
        // TODO allocate bount amount to influencer ONLY on mainnet not on plasma
    }
}
