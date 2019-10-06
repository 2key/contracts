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
 * @author Udi
 * Created at 10/03/19
 */
contract TwoKeyCPCCampaign is UpgradeableCampaign, TwoKeyCampaign, TwoKeyCampaignIncentiveModels {

    bool initialized;

    address public twoKeyDonationConversionHandler; // Contract which will handle all donations
    address public twoKeyDonationLogicHandler;
    address public mirrorCampaign;

    address[] public activeInfluencers;
    mapping(address => uint) activeInfluencer2idx;
    bytes32 public merkle_root;  // merkle root of the entire tree OR 0 - undefined, 1 - tree is empty, 2 - being computed, call computeMerkleRoots again
    // merkle tree with 2K or more leaves takes too much gas so we need to break the influencers into buckets of size <=2K
    // and compute merkle root for each bucket by calling computeMerkleRoots many times
    bytes32[] public merkle_roots;

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
        if (activeInfluencer2idx[_influencer] == 0) {
            activeInfluencers.push(_influencer);
            activeInfluencer2idx[_influencer] = activeInfluencers.length;
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

    function resetMerkleRoot(
    )
    public
    onlyModerator
    {
        // TODO this needs to be blocked or only used when using Epoches

        merkle_root = bytes32(0); // on main net. merkle root is just assigned with setMerkleRoot
        if (merkle_roots.length > 0) {
            delete merkle_roots;
        }
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

    // TODO remove this method
    function fakeInfluencers(
        uint n
    )
    public
    onlyModerator
    {
        uint L = activeInfluencers.length;
        for (uint i = 0; i < n; i++) {
            address fakeInfluencer = address(L+1000);
            activeInfluencers.push(fakeInfluencer);
            activeInfluencer2idx[fakeInfluencer] = L++;
        }
    }

    function computeMerkleRootInternal(
        bytes32[] hashes
    )
    internal
    returns (bytes32)
    {
        uint n = hashes.length;
        while (n>1) {
            for (uint i = 0; i < n; i+=2) {
                bytes32 h0 = hashes[i];
                bytes32 h1;
                if (i+1 < n) {
                    h1 = hashes[i+1];
                }
                if (h0 < h1) {
                    hashes[i>>1] = keccak256(abi.encodePacked(h0,h1));
                } else {
                    hashes[i>>1] = keccak256(abi.encodePacked(h1,h0));
                }
            }
            if ((n & (n - 1)) != 0) {
                // numberOfInfluencers is not a power of two.
                // make sure that on the next iteration it will be
                n >>= 1;
                n++;
                // lets say we start with n=5 so next n will be 3 and then 2 and then 1:
                // 0 1 2 3 4 n=5
                // (0,1) (2,3) (Z,4) n=3
                // ((0,1),(2,3)) (Z,(Z,4)) n=2
                // (((0,1),(2,3)),(Z,(Z,4))) n=1
                //
                // lets say we start with n=7 so next n will be 4 and then 2 and then 1:
                // 0 1 2 3 4 5 6 n=7
                // (0,1) (2,3) (4,5) (Z,6) n=4
                // ((0,1),(2,3)) ((4,5),(Z,6)) n=2
                // (((0,1),(2,3)),(((4,5),(Z,6))) n=1
                //
            } else {
                // lets say we start with n=8 so next n will be 4 and then 2 and then 1:
                // 0 1 2 3 4 5 6 7 n=8
                // (0,1) (2,3) (4,5) (6,7) n=4
                // ((0,1),(2,3)) ((4,5),(6,7)) n=2
                // (((0,1),(2,3)),(((4,5),(6,7))) n=1
                //
                n >>= 1;
            }
        }
        return hashes[0];
    }

    /**
     * @notice compute a merkle root of the active influencers and the amount they received.
     *         (active influencer is an influencer that received a bounty)
     *         this function does the entire computation in one call. It will take too much gas if there is more than
     *         2K leaves (active-influencers,reward) pairs
     */
    function computeMerkleRoot(
    )
    public
    onlyModerator
    {
        require(merkle_root == 0, 'merkle root already defined');
        // TODO this can only run in on plasma

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            // lock the contract without any influencer
            merkle_root = bytes32(1);
            return;
        }

        bytes32[] memory hashes = new bytes32[](numberOfInfluencers);
        uint i;
        for (i = 0; i < numberOfInfluencers; i++) {
            address influencer = activeInfluencers[i];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }
        merkle_root = computeMerkleRootInternal(hashes);
    }

    /**
     * @notice compute a merkle root of the active influencers and the amount they received.
     *         (active influencer is an influencer that received a bounty)
     *         this function needs to be called many times until merkle_root is not 2.
     *         In each call a merkle tree of up to N leaves (pair of active-influencer and amount) is
     *         computed and the result is added to merkle_roots. N should be a power of 2 for example N=2048.
     *         On all calls you have to use the same N value.
     *         Once you the leaves are computed you need to call this function one more time to compute the
     *         merkle_root of the entire tree from the intermidate results in merkle_roots
     */
    function computeMerkleRoots(
        uint N // maximnal number of leafs we are going to process in each call. for example 2**11
    )
    public
    onlyModerator
    {
        require(merkle_root == 0 || merkle_root == 2, 'merkle root already defined');
        // TODO this can only run in on plasma
        // TODO on mainnet the contractor can set this value manually

        uint numberOfInfluencers = activeInfluencers.length;
        if (numberOfInfluencers == 0) {
            // lock the contract without any influencer
            merkle_root = bytes32(1);
            return;
        }
        merkle_root = bytes32(2); // indicate that the merkle root is being computed

        uint start = merkle_roots.length * N;
        if (start >= numberOfInfluencers) {
          // in this iteration of calling this method we will compute the top merkle root from all the smaller merkle roots
          // that were computed in previous iterations
          merkle_root = computeMerkleRootInternal(merkle_roots);
          return;
        }

        uint n = numberOfInfluencers - start;
        if (n > N) {
            n = N;
        }
        bytes32[] memory hashes = new bytes32[](n);
        for (uint i = 0; i < n; i++) {
            address influencer = activeInfluencers[i+start];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }
        merkle_roots.push(computeMerkleRootInternal(hashes));
    }

    function numberOfActiveInfluencers(
    )
    public
    view
    returns (uint)
    {
        return activeInfluencers.length;
    }

    function numberOfMerkleRoots(
    )
    public
    view
    returns (uint)
    {
        return merkle_roots.length;
    }

    function getMerkleRoots(
    )
    public
    view
    returns (bytes32[])
    {
        return merkle_roots;
    }

    function getMerkleProofInternal(
        uint influencer_idx,
        bytes32[] hashes
    )
    internal
    view
    returns (bytes32[])
    {
        uint numberOfInfluencers = hashes.length;
        uint logN = 0;
        while ((1<<logN) < numberOfInfluencers) {
            logN++;
        }
        bytes32[] memory proof = new bytes32[](logN);
        logN = 0;
        while (numberOfInfluencers>1) {
            for (uint i = 0; i < numberOfInfluencers; i+=2) {
                bytes32 h0 = hashes[i];
                bytes32 h1;
                if (i+1 < numberOfInfluencers) {
                    h1 = hashes[i+1];
                }
                if (influencer_idx == i) {
                    proof[logN] = h1;
                } else if  (influencer_idx == i+1) {
                    proof[logN] = h0;
                }
                if (h0 < h1) {
                    hashes[i>>1] = keccak256(abi.encodePacked(h0,h1));
                } else {
                    hashes[i>>1] = keccak256(abi.encodePacked(h1,h0));
                }
            }
            influencer_idx >>= 1;
            if ((numberOfInfluencers & (numberOfInfluencers - 1)) != 0) {
                // numberOfInfluencers is not a power of two.
                // make sure that on the next iteration it will be
                numberOfInfluencers >>= 1;
                numberOfInfluencers++;
            } else {
                numberOfInfluencers >>= 1;
            }
            logN++;
        }
        return proof;
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in one of the merkle_roots.
     *       this function can be called only after you called computeMerkleRoots one or more times until merkle_root is not 2
     * @param _influencer the influencer for which we want to get a Merkle proof
     * @param N - the same value that was used when computeMerkleRoots was called
     * @return index to merkle_roots
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle_roots[index],
     *                 which prove that (_influencer,amount) are inside the root.
     *
     * The returned proof is only the first part of a proof to merkle_root.
     * The idea is that the code here does some of the work and the dApp code does the rest of the work to get a full proof
     * See https://github.com/2key/web3-alpha/commit/105b0b17ab3d20662b1e2171d84be25089962b68
     */
    function getMerkleProofBaseFromRoots(
        address _influencer,  // get proof for this influencer
        uint N // maximnal number of leafs we are going to process in each call. for example 2**11
    )
    public
    view
    returns (uint, bytes32[])
    {
        // TODO this can only run in on plasma
        uint influencer_idx = activeInfluencer2idx[_influencer];
        if (influencer_idx == 0) {
            return (0, new bytes32[](0));
        }
        influencer_idx--;

        uint start = N * (influencer_idx / N);
        influencer_idx -= start;

        uint n = activeInfluencers.length - start;
        if (n > N) {
            n = N;
        }
        bytes32[] memory hashes = new bytes32[](n);
        uint i;
        for (i = 0; i < n; i++) {
            address influencer = activeInfluencers[i+start];
            uint amount = referrerPlasma2Balances2key[influencer];
            hashes[i] = keccak256(abi.encodePacked(influencer,amount));
        }

        return (start/N, getMerkleProofInternal(influencer_idx, hashes));
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in the the merkle_root.
     *       this function can be called only after you called computeMerkleRoots one or more times until merkle_root is not 2
     * @param _influencer the influencer for which we want to get a Merkle proof
     * @param N - the same value that was used when computeMerkleRoots was called
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle_root,
     *                 which prove that (_influencer,amount) are inside the root.
     */
    function getMerkleProofFromRoots(
    address _influencer,  // get proof for this influencer
    uint N // maximnal number of leafs we are going to process in each call. for example 2**11
    )
    public
    view
    returns (bytes32[])
    {
        bytes32[] memory proof0;
        uint start;
        (start, proof0) = getMerkleProofBaseFromRoots(_influencer, N);
        if (proof0.length == 0) {
            return proof0; // return failury
        }
        bytes32[] memory proof1 = getMerkleProofInternal(start, merkle_roots);
        bytes32[] memory proof = new bytes32[](proof0.length + proof1.length);
        uint i;
        for (i = 0; i < proof0.length; i++) {
            proof[i] = proof0[i];
        }
        for (i = 0; i < proof1.length; i++) {
            proof[i+proof0.length] = proof1[i];
        }

        return proof;
    }

    /**
     * @notice compute a merkle proof that influencer and amount are in the merkle root.
     * @param _influencer the influencer for which we want to get a Merkle proof
     * @return proof - array of hashes that can be used with _influencer and amount to compute the merkle root,
     *                 which prove that (_influencer,amount) are inside the root.
     */
    function getMerkleProof(
      address _influencer  // get proof for this influencer
    )
    public
    view
    returns (bytes32[])
    {
      // TODO this can only run in on plasma
      uint influencer_idx = activeInfluencer2idx[_influencer];
      if (influencer_idx == 0) {
        return new bytes32[](0);
      }
      influencer_idx--;

      uint numberOfInfluencers = activeInfluencers.length;
      bytes32[] memory hashes = new bytes32[](numberOfInfluencers);
      uint i;
      for (i = 0; i < numberOfInfluencers; i++) {
        address influencer = activeInfluencers[i];
        uint amount = getReferrerPlasmaBalance(influencer);
        hashes[i] = keccak256(abi.encodePacked(influencer,amount));
      }

      return getMerkleProofInternal(influencer_idx, hashes);
    }

    /**
     * @notice validate a merkle proof.
     */
    function checkMerkleProof(
        address influencer,
        bytes32[] proof,
        uint amount
    )
    public
    view
    returns (bool)
    {
        if(merkle_root == 0) // merkle root was not yet set by contractor
            return false;
        influencer = twoKeyEventSource.plasmaOf(influencer);
        return MerkleProof.verifyProof(proof,merkle_root,keccak256(abi.encodePacked(influencer,amount)));
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
        // TODO check that this is called only once by msg.sender
        require(checkMerkleProof(msg.sender,proof,amount), 'proof is invalid');
        // TODO allocate bount amount to influencer ONLY on mainnet not on plasma
    }
}
