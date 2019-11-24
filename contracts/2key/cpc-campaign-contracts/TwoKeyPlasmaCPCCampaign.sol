pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../libraries/Call.sol";
import "../libraries/MerkleProof.sol";
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

    bool isCampaignInitialized;
    bool boughtRewardsWithEther;
    bool usd2KEYrateWei;
    uint reservedAmountOfTokens; // Reserved amount of tokens for the converters who are pending approval

    address[] public activeInfluencers;
    mapping(address => uint) activeInfluencer2idx;
    bytes32 public merkle_root;  // merkle root of the entire tree OR 0 - undefined, 1 - tree is empty, 2 - being computed, call computeMerkleRoots again
    // merkle tree with 2K or more leaves takes too much gas so we need to break the influencers into buckets of size <=2K
    // and compute merkle root for each bucket by calling computeMerkleRoots many times
    bytes32[] public merkle_roots;

    string public target_url;
    function setTargetUrl(
        string _url
    )
    public
    {
        require(isCampaignInitialized == false);
        target_url = _url;
    }

    address public mirrorCampaign;
    function setMirrorCampaign(address _mirrorCampaign) {
        require(mirrorCampaign == address(0),'cpc6');
        mirrorCampaign = _mirrorCampaign;
    }



    //===========================================
    //MAIN FUNCTIONS:
    //===========================================



    function setInitialParamsCampaign(
        address _contractor,
        address _twoKeySingletonRegistry,
        address _conversionHandler,
        address _logicHandler,
        uint [] numberValues
    )
    public
    {
        require(isCampaignInitialized == false);

        contractor = _contractor;
        conversionHandler = _conversionHandler;
        logicHandler = _logicHandler;

        //TODO: unique/tailored/contractor chosen Moderator addresses

        twoKeySingletonesRegistry = _twoKeySingletonRegistry;
        twoKeyEventSource = TwoKeyEventSource(getContractProxyAddress("TwoKeyEventSource"));
        twoKeyEconomy = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonesRegistry).getNonUpgradableContractAddress("TwoKeyEconomy");

        maxReferralRewardPercent = numberValues[0];
        conversionQuota = numberValues[1];
        if(values[2] == 1) {
            mustConvertToReferr = true;
        }
        totalSupply_ = values[3];

        ownerPlasma = twoKeyEventSource.plasmaOf(_contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;

        isCampaignInitialized = true;
    }

    /**
    * @notice Function to add fiat inventory for rewards
    * @dev only contractor can add this inventory
    */
    function specifyConversionReward()
    public
    onlyContractor
    payable
    {
        //It can be called only ONCE per campaign
        require(usd2KEYrateWei == 0);

        boughtRewardsWithEther = true;
        uint amountOfTwoKeys = buyTokensFromUpgradableExchange(msg.value, address(this));
        uint rateUsdToEth = ITwoKeyExchangeRateContract(getContractProxyAddress("TwoKeyExchangeRateContract")).getBaseToTargetRate("USD");

        usd2KEYrateWei = (msg.value).mul(rateUsdToEth).div(amountOfTwoKeys); //0.1 DOLLAR
    }


    //((%**%&@#$&%@*#$%*@#$%&@#$%&*@#$%*@#$%(@#$%*@#$*%(@#$%(@(#$%(@#($%(@#$%(@#$%(@#$(%


    //===========================================
    //PLASMA FUNCTIONS:
    //===========================================

    event ConvertSig(address indexed influencer, bytes signature, address plasmaConverter, bytes moderatorSig);

    //Referral accounting stuff
    mapping(address => uint256) private referrerPlasma2cut; // Mapping representing how much are cuts in percent(0-100) for referrer address


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
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convertConverterValue(
        bytes signature, address converter, uint value
    )
    private
    returns (address[])
    {
        bool canConvert = ITwoKeyDonationLogicHandler(twoKeyCPCLogicHandler).checkAllRequirementsForConversionAndTotalRaised(
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
            ITwoKeyDonationLogicHandler(twoKeyCPCLogicHandler).updateRefchainRewards(
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
        address[] memory influencers = ITwoKeyDonationLogicHandler(twoKeyCPCLogicHandler).getReferrers(last_influencer);
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
        require(msg.sender == twoKeyCPCLogicHandler);
        if (activeInfluencer2idx[_influencer] == 0) {
            activeInfluencers.push(_influencer);
            activeInfluencer2idx[_influencer] = activeInfluencers.length;
        }
        referrerPlasma2Balances2key[_influencer] = referrerPlasma2Balances2key[_influencer].add(_balance);
    }


    /**
     * @notice Function to get reserved amount of rewards
     */
    function getReservedAmount2keyForRewards() public view returns (uint) {
        return reservedAmount2keyForRewards;
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
    onlyContractorOrMaintainer
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
    onlyContractorOrMaintainer
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
}
