pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";

import "../libraries/IncentiveModels.sol";
import "../TwoKeyConverterStates.sol";
import "../TwoKeyConversionStates.sol";

import "../interfaces/ITwoKeyDonationConversionHandler.sol";
import "../interfaces/ITwoKeyDonationLogicHandler.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/19/19
 */
contract TwoKeyDonationCampaign is UpgradeableCampaign, TwoKeyCampaignIncentiveModels, TwoKeyCampaign {

    bool initialized;

    bool acceptsFiat; // Will determine if fiat conversion can be created or not


    function setInitialParamsDonationCampaign(
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
        require(numberValues[0] <= 100*(10**18)); //Require that max referral reward percent is less than 100%
        contractor = _contractor;
        moderator = _moderator;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));
                twoKeyEconomy = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
                    .getNonUpgradableContractAddress("TwoKeyEconomy");
        totalSupply_ = 1000000;

        maxReferralRewardPercent = numberValues[0];
        conversionQuota = numberValues[6];

        conversionHandler = _twoKeyDonationConversionHandler;
        logicHandler = _twoKeyDonationLogicHandler;


        mustConvertToReferr = booleanValues[0];
        isKYCRequired = booleanValues[1];
        acceptsFiat = booleanValues[2];


        ownerPlasma = twoKeyEventSource.plasmaOf(_contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;

        //Because of stack depth
        ITwoKeyDonationConversionHandler(conversionHandler).setExpiryConversionInHours(numberValues[10]);

        initialized = true;
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
        require(msg.sender == conversionHandler);
        contractorTotalProceeds = contractorTotalProceeds.add(value);
        contractorBalance = contractorBalance.add(value);
    }


    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convert(
        bytes signature
    )
    public
    payable
    {
        bool canConvert;
        uint conversionAmountCampaignCurrency;

        uint conversionAmount;
        uint debtPaid;
        (conversionAmount,debtPaid) = payFeesForUser(msg.sender, msg.value);

        (canConvert, conversionAmountCampaignCurrency) = ITwoKeyDonationLogicHandler(logicHandler).checkAllRequirementsForConversionAndTotalRaised(
            msg.sender,
            conversionAmount,
            debtPaid
        );

        require(canConvert == true);

        address _converterPlasma = twoKeyEventSource.plasmaOf(msg.sender);
        uint numberOfInfluencers = distributeArcsIfNecessary(msg.sender, signature);
        createConversion(conversionAmount, msg.sender, conversionAmountCampaignCurrency, numberOfInfluencers);
    }

    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     */
    function createConversion(
        uint conversionAmountEthWEI,
        address converterAddress,
        uint conversionAmountCampaignCurrency,
        uint numberOfInfluencers
    )
    private
    {
        uint maxReferralRewardFiatOrETHWei = calculateInfluencersFee(conversionAmountEthWEI, numberOfInfluencers);

        uint conversionId = ITwoKeyDonationConversionHandler(conversionHandler).supportForCreateConversion(
            converterAddress,
            conversionAmountEthWEI,
            maxReferralRewardFiatOrETHWei,
            isKYCRequired,
            conversionAmountCampaignCurrency
        );
        //If KYC is not required conversion is automatically executed
        if(isKYCRequired == false) {
            ITwoKeyDonationConversionHandler(conversionHandler).executeConversion(conversionId);
        }
    }

    /**
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
        require(msg.sender == conversionHandler);
        //Fiat rewards = fiatamount * moderatorPercentage / 100  / 0.095
        uint totalBounty2keys = 0;
        if(_maxReferralRewardETHWei > 0) {
            //Buy tokens from upgradable exchange
            (totalBounty2keys,) = buyTokensFromUpgradableExchange(_maxReferralRewardETHWei, address(this));
        }
        //Handle refchain rewards
        ITwoKeyDonationLogicHandler(logicHandler).updateRefchainRewards(
            _converter,
            _conversionId,
            totalBounty2keys);

        reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalBounty2keys);
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
        address[] memory influencers = ITwoKeyDonationLogicHandler(logicHandler).getReferrers(last_influencer);
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
     * @notice Contractor can withdraw funds only if criteria is satisfied
     */
    function withdrawContractor() public onlyContractor {
        withdrawContractorInternal();
    }

    /**
     * @notice Function to get reserved amount of rewards
     */
    function getReservedAmount2keyForRewards() public view returns (uint) {
        return reservedAmount2keyForRewards;
    }

    function referrerWithdraw(
        address _address,
        bool _withdrawAsStable
    )
    public
    {
        referrerWithdrawInternal(_address, _withdrawAsStable);
    }


}
