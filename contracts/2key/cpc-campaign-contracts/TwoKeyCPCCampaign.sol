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
     * @notice Function which will buy tokens from upgradable exchange for moderator
     * @param moderatorFee is the fee in tokens moderator earned
     */
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public
    onlyTwoKeyConversionHandler
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
    onlyContractorOrMaintainer
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
    onlyContractorOrMaintainer
    {
        require(merkle_root == 0, 'merkle root already defined');
        // TODO this can only run in on mainet
        merkle_root = _merkle_root;
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



    /**
     * @notice validate a merkle proof - validates required cashout for thie referrrer
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
     * @notice validate a merkle proof. - for mainnet- claim payment by referrer on the public chain
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
        // TODO allocate bounty amount to influencer ONLY on mainnet not on plasma
    }
}
