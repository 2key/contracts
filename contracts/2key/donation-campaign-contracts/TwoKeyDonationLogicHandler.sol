pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyDonationCampaign.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../interfaces/ITwoKeyDonationConversionHandler.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../libraries/SafeMath.sol";

import "../libraries/IncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignLogicHandler.sol";

contract TwoKeyDonationLogicHandler is UpgradeableCampaign, TwoKeyCampaignLogicHandler {

    uint powerLawFactor;

    uint campaignGoal; // Goal of the campaign, how many funds to raise


    function setInitialParamsDonationLogicHandler(
        uint[] numberValues,
        string _currency,
        address _contractor,
        address _moderator,
        address twoKeySingletonRegistry,
        address _twoKeyDonationCampaign,
        address _twoKeyDonationConversionHandler
    )
    public
    {
        require(initialized == false);

        twoKeyCampaign = _twoKeyDonationCampaign;
        conversionHandler = _twoKeyDonationConversionHandler;

        powerLawFactor = 2;
        campaignStartTime = numberValues[1];
        campaignEndTime = numberValues[2];
        minContributionAmountWei = numberValues[3];
        maxContributionAmountWei = numberValues[4];
        campaignGoal = numberValues[5];
        incentiveModel = IncentiveModel(numberValues[7]);

        if(numberValues[8] == 1) {
            endCampaignOnceGoalReached = true;
        }

        contractor = _contractor;
        moderator = _moderator;
        currency = _currency;

        twoKeySingletonRegistry = twoKeySingletonRegistry;
        twoKeyEventSource = getAddressFromRegistry("TwoKeyEventSource");
        twoKeyMaintainersRegistry = getAddressFromRegistry("TwoKeyMaintainersRegistry");
        twoKeyRegistry = getAddressFromRegistry("TwoKeyRegistry");

        ownerPlasma = plasmaOf(contractor);
        initialized = true;
    }

    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount) external returns (bool) {
        require(msg.sender == twoKeyCampaign);
        require(canConversionBeCreatedInTermsOfMinMaxContribution(converter, conversionAmount) == true);
        require(updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(conversionAmount) == true);
        require(checkIsCampaignActiveInTermsOfTime() == true);
        return true;
    }

    function canConversionBeCreatedInTermsOfMinMaxContribution(address converter, uint conversionAmountEthWEI) internal view returns (bool) {
        uint leftToSpendInCampaignCurrency = checkHowMuchUserCanSpend(converter);
        if(keccak256(currency) == keccak256("ETH")) {
            if(leftToSpendInCampaignCurrency >= conversionAmountEthWEI && conversionAmountEthWEI >= minContributionAmountWei) {
                return true;
            }
        } else {
            uint rate = getRateFromExchange();
            uint conversionAmountConverted = (conversionAmountEthWEI.mul(rate)).div(10**18);
            if(leftToSpendInCampaignCurrency >= conversionAmountConverted && conversionAmountConverted >= minContributionAmountWei) {
                return true;
            }
        }
        return false;
    }

    function checkHowMuchUserCanSpend(
        address _converter
    )
    public
    view
    returns (uint)
    {
        uint amountAlreadySpentEth = ITwoKeyDonationConversionHandler(conversionHandler).getAmountConverterSpent(_converter);
        uint leftToSpend = getHowMuchLeftForUserToSpend(amountAlreadySpentEth);
        return leftToSpend;
    }

    /**
     * @notice Function to check for some user how much he can donate
     */
    function getHowMuchLeftForUserToSpend(
        uint alreadyDonatedEthWEI
    )
    internal
    view
    returns (uint)
    {
        if(keccak256(currency) == keccak256('ETH')) {
            uint availableToDonate = maxContributionAmountWei.sub(alreadyDonatedEthWEI);
            return availableToDonate;
        } else {
            uint rate = getRateFromExchange();

            uint totalAmountSpentConvertedToFIAT = (alreadyDonatedEthWEI*rate).div(10**18);
            uint limit = maxContributionAmountWei; // Initially we assume it's fiat currency campaign
            uint leftToSpendInFiats = limit.sub(totalAmountSpentConvertedToFIAT);
            return leftToSpendInFiats;
        }
    }



    function updateReferrerMappings(
        address referrerPlasma,
        uint reward,
        uint conversionId
    )
    internal
    {
        ITwoKeyDonationCampaign(twoKeyCampaign).updateReferrerPlasmaBalance(referrerPlasma,reward);
        referrerPlasma2TotalEarnings2key[referrerPlasma] = referrerPlasma2TotalEarnings2key[referrerPlasma].add(reward);
        referrerPlasma2EarningsPerConversion[referrerPlasma][conversionId] = reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] += 1;
        ITwoKeyEventSourceEvents(twoKeyEventSource).rewarded(twoKeyCampaign, referrerPlasma, reward);
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _maxReferralRewardETHWei is the max referral reward set
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId,
        uint totalBounty2keys
    )
    public
    {
        require(msg.sender == twoKeyCampaign);

//        Get all the influencers
        address[] memory influencers = getReferrers(_converter);

        //Get array length
        uint numberOfInfluencers = influencers.length;

        uint i;
        uint reward;
        if(incentiveModel == IncentiveModel.VANILLA_AVERAGE) {
            reward = IncentiveModels.averageModelRewards(totalBounty2keys, numberOfInfluencers);
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], reward, _conversionId);

            }
        } else if (incentiveModel == IncentiveModel.VANILLA_AVERAGE_LAST_3X) {
            uint rewardForLast;
            // Calculate reward for regular ones and for the last
            (reward, rewardForLast) = IncentiveModels.averageLast3xRewards(totalBounty2keys, numberOfInfluencers);
            if(numberOfInfluencers > 0) {
                //Update equal rewards to all influencers but last
                for(i=0; i<numberOfInfluencers - 1; i++) {
                    updateReferrerMappings(influencers[i], reward, _conversionId);
                }
                updateReferrerMappings(influencers[numberOfInfluencers-1], rewardForLast, _conversionId);
            }
        } else if(incentiveModel == IncentiveModel.VANILLA_POWER_LAW) {
            // Get rewards per referrer
            uint [] memory rewards = IncentiveModels.powerLawRewards(totalBounty2keys, numberOfInfluencers, 2);
            //Iterate through all referrers and distribute rewards
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], rewards[i], _conversionId);
            }
        } else if(incentiveModel == IncentiveModel.MANUAL) {
            for (i = 0; i < numberOfInfluencers; i++) {
                uint256 b;

                if (i == influencers.length - 1) {  // if its the last influencer then all the bounty goes to it.
                    b = totalBounty2keys;
                }
                else {
                    uint256 cut = ITwoKeyCampaign(twoKeyCampaign).getReferrerCut(influencers[i]);
                    if (cut > 0 && cut <= 101) {
                        b = totalBounty2keys.mul(cut.sub(1)).div(100);
                    } else {// cut == 0 or 255 indicates equal particine of the bounty
                        b = totalBounty2keys.div(influencers.length - i);
                    }
                }

                updateReferrerMappings(influencers[i], b, _conversionId);
                //Decrease bounty for distributed
                totalBounty2keys = totalBounty2keys.sub(b);
            }
        }
    }

    /**
     * @notice Function to return referrers participated in the referral chain
     * @param customer is the one who converted (bought tokens)
     * @return array of referrer addresses
     */
    function getReferrers(
        address customer
    )
    public
    view
    returns (address[])
    {
        address influencer = plasmaOf(customer);
        uint n_influencers = 0;

        while (true) {
            influencer = plasmaOf(ITwoKeyCampaign(twoKeyCampaign).getReceivedFrom(influencer));
            if (influencer == plasmaOf(contractor)) {
                break;
            }
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        influencer = plasmaOf(customer);

        while (n_influencers > 0) {
            influencer = plasmaOf(ITwoKeyCampaign(twoKeyCampaign).getReceivedFrom(influencer));
            n_influencers--;
            influencers[n_influencers] = influencer;
        }
        return influencers;
    }



    /**
     * @notice Function to fetch stats for the address
     */
    function getAddressStatistic(
        address _address,
        bool plasma,
        bool flag,
        address referrer
    )
    internal
    view
    returns (bytes)
    {
        bytes32 state; // NOT-EXISTING AS CONVERTER DEFAULT STATE

        address eth_address = ethereumOf(_address);
        address plasma_address = plasmaOf(_address);

        if(_address == contractor) {
            abi.encodePacked(0, 0, 0, false, false);
        } else {
            bool isConverter;
            bool isReferrer;

            uint amountConverterSpent = ITwoKeyDonationConversionHandler(conversionHandler).getAmountConverterSpent(eth_address);
            uint amountOfTokensReceived = ITwoKeyDonationConversionHandler(conversionHandler).getAmountOfDonationTokensConverterReceived(eth_address);

            if(amountConverterSpent> 0) {
                isConverter = true;
                state = ITwoKeyDonationConversionHandler(conversionHandler).getStateForConverter(eth_address);
            }

            if(referrerPlasma2TotalEarnings2key[plasma_address] > 0) {
                isReferrer = true;
            }

            return abi.encodePacked(
                amountConverterSpent,
                referrerPlasma2TotalEarnings2key[plasma_address],
                amountOfTokensReceived,
                isConverter,
                isReferrer,
                state
            );
        }
    }


    function getSuperStatistics(
        address _user,
        bool plasma,
        bytes signature
    )
    public
    view
    returns (bytes)
    {
        address eth_address = _user;

        if (plasma) {
            (eth_address) = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_user);
        }

        bytes memory userData = ITwoKeyReg(twoKeyRegistry).getUserData(eth_address);

        bool isJoined = getAddressJoinedStatus(_user);
        bool flag;

        address _address;

        if(msg.sender == contractor || msg.sender == eth_address) {
            flag = true;
        } else {
            _address = recover(signature);
            if(_address == ownerPlasma) {
                flag = true;
            }
        }
        bytes memory stats = getAddressStatistic(_user, plasma, flag, _address);
        return abi.encodePacked(userData, isJoined, eth_address, stats);
    }


    /**
     * @notice Function which will calculate how much will be raised including the conversion which try to be created
     * @param conversionAmount is the amount of conversion
     */
    function calculateRaisedFundsIncludingNewConversion(uint conversionAmount) internal view returns (uint) {
        uint total = 0;
        if(keccak256(currency) == keccak256('ETH')) {
            total = campaignRaisedAlready.add(conversionAmount);
        } else {
            uint rate = getRateFromExchange();
            total = ((conversionAmount*rate).div(10**18)).add(campaignRaisedAlready);
        }
        return total;
    }

    /**
     * @notice Function which will update total raised funds which will be always compared with hard cap
     * @param newAmount is the value including the new conversion amount
     */
    function updateTotalRaisedFunds(uint newAmount) internal {
        campaignRaisedAlready = newAmount;
    }

    /**
     * @notice Function to update total raised funds and validate conversion in terms of campaign goal
     */
    function updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(uint conversionAmount) internal returns (bool) {
        uint newTotalRaisedFunds = calculateRaisedFundsIncludingNewConversion(conversionAmount); // calculating new total raised funds
        require(canConversionBeCreatedInTermsOfCampaignGoal(newTotalRaisedFunds)); // checking that criteria is satisfied
        updateTotalRaisedFunds(newTotalRaisedFunds); //updating new total raised funds
        return true;
    }

    /**
     * @notice Function which will validate if conversion can be created if endCampaignOnceGoalReached is selected
     * @param campaignRaisedIncludingConversion is how much will be total campaign raised with new conversion
     */
    function canConversionBeCreatedInTermsOfCampaignGoal(uint campaignRaisedIncludingConversion) internal view returns (bool) {
        if(endCampaignOnceGoalReached == true) {
            require(campaignRaisedIncludingConversion <= campaignGoal + minContributionAmountWei); //small GAP
        }
        return true;
    }


    /**
     * @notice Function to check if campaign has ended
     */
    function isCampaignEnded() internal view returns (bool) {
        if(checkIsCampaignActiveInTermsOfTime() == false) {
            return true;
        }
        if(endCampaignOnceGoalReached == true && campaignRaisedAlready.add(minContributionAmountWei) >= campaignGoal) {
            return true;
        }
        return false;
    }

    function getConstantInfo()
    public
    view
    returns (uint,uint,uint,uint)
    {
        return (campaignStartTime,campaignEndTime, minContributionAmountWei, maxContributionAmountWei);
    }
}
