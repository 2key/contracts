pragma solidity ^0.4.24;

import "../campaign-mutual-contracts/TwoKeyCampaign.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyConversionHandler.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
/**
 * @author Nikola Madjarevic
 */
contract TwoKeyAcquisitionCampaignERC20 is UpgradeableCampaign, TwoKeyCampaign {

    address assetContractERC20; // Asset contract is address of ERC20 inventory
    bool public boughtRewardsWithEther;

    uint public usd2KEYrateWei;
    uint reservedAmountOfTokens; // Reserved amount of tokens for the converters who are pending approval
    bool public withdrawUnsoldTokensCalled;

    /**
     * @notice This function is simulation for the constructor, since we're relying on proxies
     * @param _twoKeySingletonesRegistry is the address of TwoKeySingletonsRegistry contract
     * @param _twoKeyAcquisitionLogicHandler is the address of TwoKeyAcquisitionLogicHandler contract
     * @param _conversionHandler is the address of TwoKeyConversionHandler contract
     * @param _moderator is the moderator address
     * @param _assetContractERC20 is the ERC20 contract being sold inside campaign
     * @param _contractor is the contractor of the campaign
     * @param values is the array containing values [maxReferralRewardPercent (in weis), conversionQuota]
     */
    function setInitialParamsCampaign(
        address _twoKeySingletonesRegistry,
        address _twoKeyAcquisitionLogicHandler,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        address _contractor,
        address _twoKeyEconomy,
        uint [] values
    )
    public
    {
        require(isCampaignInitialized == false); // Security layer to make sure the function will act as a constructor
        require(values[0] <= 100*(10**18)); // Require that max referral reward is less than 100%

        contractor = _contractor;
        moderator = _moderator;

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;

        twoKeyEventSource = TwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));
        twoKeyEconomy = _twoKeyEconomy;

        maxReferralRewardPercent = values[0];
        conversionQuota = values[1];

        if(values[2] == 1) {
            isKYCRequired = true;
        }

        if(values[3] == 1) {
            mustConvertToReferr = true;
        }

        totalSupply_ = values[4];

        ownerPlasma = twoKeyEventSource.plasmaOf(contractor);
        received_from[ownerPlasma] = ownerPlasma;
        balances[ownerPlasma] = totalSupply_;


        logicHandler = _twoKeyAcquisitionLogicHandler;
        conversionHandler = _conversionHandler;
        assetContractERC20 = _assetContractERC20;

        isCampaignInitialized = true;
    }



    /**
     * @notice      Internal function to check the balance of the specific ERC20 on this contract
     *
     * @param       tokenAddress is the ERC20 contract address
     */
    function getTokenBalance(
        address tokenAddress
    )
    internal
    view
    returns (uint)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @notice      Function to add fiat inventory for rewards
     * @dev         Only contractor can add this inventory
     *              This method can be called only once per the campaign.
     */
    function specifyFiatConversionRewards()
    public
    onlyContractor
    payable
    {
        require(usd2KEYrateWei == 0);

        boughtRewardsWithEther = true;

        // Second returned argument is rate on which token is bought
        (,usd2KEYrateWei)= buyTokensFromUpgradableExchange(msg.value, address(this));
    }


    function validateRequirements(
        bool _isFiat,
        uint _conversionAmount,
        uint _debtPaid
    )
    internal
    returns (uint)
    {
        bool canConvert;
        uint conversionAmountCampaignCurrency;
        (canConvert, conversionAmountCampaignCurrency) = ITwoKeyAcquisitionLogicHandler(logicHandler).checkAllRequirementsForConversionAndTotalRaised(
            msg.sender,
            _conversionAmount,
            _isFiat,
            _debtPaid);

        require(canConvert==true);
        return conversionAmountCampaignCurrency;
    }


    /**
     * @notice Function where converter can convert
     * @dev payable function
     */
    function convert(
        bytes signature,
        bool _isAnonymous
    )
    public
    payable
    {
        uint conversionAmount;
        uint debtPaid;
        (conversionAmount, debtPaid) = payFeesForUser(msg.sender, msg.value);
        uint conversionAmountCampaignCurrency = validateRequirements(false, conversionAmount, debtPaid);
        uint numberOfInfluencers = distributeArcsIfNecessary(msg.sender, signature);
        createConversion(
            conversionAmount,
            msg.sender,
            false,
            _isAnonymous,
            conversionAmountCampaignCurrency,
            numberOfInfluencers
        );
    }

    /**
     * @notice Function to convert if the conversion is in fiat
     * @dev This can be executed only in case currency is fiat
     * @param _converter is the address of converter who want's fiat conversion
     * @param conversionAmountFiatWei is the amount of conversion converted to wei units
     * @param _isAnonymous if converter chooses to be anonymous
     */
    function convertFiat(
        bytes signature,
        address _converter,
        uint conversionAmountFiatWei,
        bool _isAnonymous
    )
    public
    {
        // Validate that sender is either _converter or maintainer
        require(msg.sender == _converter || twoKeyEventSource.isAddressMaintainer(msg.sender));
        uint conversionAmountCampaignCurrency = validateRequirements(true, conversionAmountFiatWei, 0);
        uint numberOfInfluencers = distributeArcsIfNecessary(_converter, signature);
        createConversion(
            conversionAmountFiatWei,
            _converter,
            true,
            _isAnonymous,
            conversionAmountCampaignCurrency,
            numberOfInfluencers
        );
    }


    function validateThatThereIsEnoughTokensAndIncreaseReserved(
        uint totalBoughtUnits
    )
    public
    onlyTwoKeyConversionHandler
    {
        uint256 _total_units = getAvailableAndNonReservedTokensAmount();
        require(_total_units >= totalBoughtUnits);

        reservedAmountOfTokens = reservedAmountOfTokens.add(totalBoughtUnits);
    }



    /*
     * @notice Function which is executed to create conversion
     * @param conversionAmountETHWeiOrFiat is the amount of the ether sent to the contract
     * @param converterAddress is the sender of eth to the contract
     */
    function createConversion(
        uint conversionAmountETHWeiOrFiat,
        address converterAddress,
        bool isFiatConversion,
        bool isAnonymous,
        uint conversionAmountCampaignCurrency,
        uint numberOfInfluencers
    )
    private
    {

        uint conversionId = ITwoKeyConversionHandler(conversionHandler).supportForCreateConversion(
            converterAddress,
            conversionAmountETHWeiOrFiat,
            calculateInfluencersFee(conversionAmountETHWeiOrFiat, numberOfInfluencers),
            isFiatConversion,
            isAnonymous,
            conversionAmountCampaignCurrency
        );

        if(isKYCRequired == false) {
            if(isFiatConversion == false || ITwoKeyConversionHandler(conversionHandler).isFiatConversionAutomaticallyApproved()) {
                ITwoKeyConversionHandler(conversionHandler).executeConversion(conversionId);
            }
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
        uint _conversionId,
        bool _isConversionFiat
    )
    public
    onlyTwoKeyConversionHandler
    returns (uint)
    {
        //Fiat rewards = fiatamount * moderatorPercentage / 100  / 0.095
        uint totalBounty2keys = 0;
        //If fiat conversion do exactly the same just send different reward and don't buy tokens, take them from contract
        if(_maxReferralRewardETHWei > 0) {
            if(_isConversionFiat) {
                if(usd2KEYrateWei == 0) {
                    usd2KEYrateWei = (IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key());
                }
                totalBounty2keys = ((_maxReferralRewardETHWei.mul(10**18)).div(usd2KEYrateWei));
                reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalBounty2keys);
            } else {
                //Buy tokens from upgradable exchange
                (totalBounty2keys,) = buyTokensFromUpgradableExchange(_maxReferralRewardETHWei, address(this));
                reservedAmount2keyForRewards = reservedAmount2keyForRewards.add(totalBounty2keys);
            }
            // Update reserved amount
        }
        //Handle refchain rewards
        ITwoKeyAcquisitionLogicHandler(logicHandler).updateRefchainRewards(
            _converter,
            _conversionId,
            totalBounty2keys);

        return totalBounty2keys;
    }


    /**
     * @notice Move some amount of ERC20 from our campaign to someone
     * @param _to address we're sending the amount of ERC20
     * @param _amount is the amount of ERC20's we're going to transfer
     * @return true if successful, otherwise reverts
     */
    function moveFungibleAsset(
        address _to,
        uint256 _amount
    )
    public
    onlyTwoKeyConversionHandler
    {
        IERC20(assetContractERC20).transfer(_to, _amount);
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
    onlyTwoKeyConversionHandler
    {
        contractorTotalProceeds = contractorTotalProceeds.add(value);
        contractorBalance = contractorBalance.add(value);
    }

    /**
     * @notice Function to update amount of the reserved tokens in case conversion is rejected
     * @param value is the amount to reduce from reserved state
     */
    function updateReservedAmountOfTokensIfConversionRejectedOrExecuted(
        uint value
    )
    public
    onlyTwoKeyConversionHandler
    {
        reservedAmountOfTokens = reservedAmountOfTokens.sub(value);
    }

    /**
     * @notice Function to return status of inventory
     * @return current ERC20 balance on inventory address, reserved amount of tokens for converters,
     * and reserved amount of tokens for the rewards
     */
    function getInventoryStatus()
    public
    view
    returns (uint,uint,uint,uint)
    {
        uint inventoryBalance = getTokenBalance(assetContractERC20);
        if(assetContractERC20 == twoKeyEconomy) {
            return (inventoryBalance, reservedAmountOfTokens, reservedAmount2keyForRewards, inventoryBalance);
        } else {
            return (inventoryBalance, reservedAmountOfTokens, reservedAmount2keyForRewards, getTokenBalance(twoKeyEconomy));
        }
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
        address[] memory influencers = ITwoKeyAcquisitionLogicHandler(logicHandler).getReferrers(last_influencer);
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
     * @notice Function to check available amount of the tokens on the contract
     */
    function getAvailableAndNonReservedTokensAmount()
    public
    view
    returns (uint)
    {
        uint inventoryBalance = getTokenBalance(assetContractERC20);
        if(assetContractERC20 == twoKeyEconomy) {
            return (inventoryBalance.sub(reservedAmountOfTokens.add(reservedAmount2keyForRewards)));
        }
        return (inventoryBalance.sub(reservedAmountOfTokens));
    }

    /**
     * @notice Function to fetch contractor balance in ETH
     * @dev only contractor can call this function, otherwise it will revert
     * @return value of contractor balance in ETH WEI
     */
    function getContractorBalance()
    external
    view
    returns (uint)
    {
        return contractorBalance;
    }

    /**
     * @notice Function where contractor can withdraw his earnings after campaign ends
     * @dev onlyContractor can call this function
     */
    function withdrawContractor()
    public
    onlyContractor
    {
        withdrawContractorInternal();
    }


    /**
     * @notice Function to withdraw remaining rewards inventory in the contract
     */
    function withdrawRemainingRewardsInventory()
    internal
    returns (uint)
    {
        uint tokensBalance = getTokenBalance(twoKeyEconomy);
        uint rewardsNotSpent = tokensBalance.sub(reservedAmount2keyForRewards);
        if(rewardsNotSpent > 0) {
            IERC20(twoKeyEconomy).transfer(contractor, rewardsNotSpent);
        }
        return rewardsNotSpent;
    }


    /**
     * @notice Function where contractor can withdraw all unsold tokens and all inventory which is not spent
     * from his campaign once time requirement is satisfied
     */
    function withdrawUnsoldTokens() public onlyContractor {
        require(ITwoKeyAcquisitionLogicHandler(logicHandler).canContractorWithdrawUnsoldTokens() == true);
        require(withdrawUnsoldTokensCalled == false);
        uint unsoldTokens = getAvailableAndNonReservedTokensAmount();
        IERC20(assetContractERC20).transfer(contractor, unsoldTokens);

        if(assetContractERC20 != twoKeyEconomy) {
            if(boughtRewardsWithEther == false) {
                withdrawRemainingRewardsInventory();
            } else {
                if(block.timestamp >= ITwoKeyAdmin(getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin")).getTwoKeyRewardsReleaseDate() == true) {
                    uint rewardsNotSpent = withdrawRemainingRewardsInventory();
                    IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange"))
                        .report2KEYWithdrawnFromNetwork(rewardsNotSpent);
                }
            }
        }
        withdrawUnsoldTokensCalled = true;
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

