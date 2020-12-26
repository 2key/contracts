pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyDonationCampaign.sol";
import "../interfaces/ITwoKeyDonationConversionHandler.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../libraries/SafeMath.sol";

import "../libraries/IncentiveModels.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";
import "../campaign-mutual-contracts/TwoKeyCampaignLogicHandler.sol";

contract TwoKeyDonationLogicHandler is UpgradeableCampaign, TwoKeyCampaignLogicHandler {

    uint public powerLawFactor; // Factor

    uint campaignGoal; // Goal of the campaign, how many funds to raise


    function setInitialParamsDonationLogicHandler(
        uint[] numberValues,
        string _currency,
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
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

        if(keccak256(_currency) == keccak256('ETH')) {
            require(numberValues[3] >= (10**16));
        } else {
            require(numberValues[3] >= (10**18));
        }

        if(numberValues[8] == 1) {
            endCampaignOnceGoalReached = true;
        }

        contractor = _contractor;
        moderator = _moderator;
        currency = _currency;

        if(keccak256(_currency) == keccak256('ETH')) {
            require(numberValues[3] >= (10**16));
        } else {
            require(numberValues[3] >= (10**18));
        }

        twoKeySingletonRegistry = _twoKeySingletonRegistry;
        twoKeyRegistry = getAddressFromRegistry("TwoKeyRegistry");

        ownerPlasma = plasmaOf(contractor);
        initialized = true;
    }

    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, uint debtPaid) public returns (bool,uint) {
        require(msg.sender == twoKeyCampaign);
        require(canConversionBeCreatedInTermsOfMinMaxContribution(converter, conversionAmount.add(debtPaid)) == true);
        uint conversionAmountInCampaignCurrency = convertConversionAmountToCampaignCurrency(conversionAmount);
        require(updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(conversionAmountInCampaignCurrency) == true);
        require(checkIsCampaignActiveInTermsOfTime() == true);
        return (true, conversionAmountInCampaignCurrency);
    }

    function canConversionBeCreatedInTermsOfMinMaxContribution(address converter, uint conversionAmountEthWEI) public view returns (bool) {
        uint leftToSpendInCampaignCurrency = checkHowMuchUserCanSpend(converter);
        if(keccak256(currency) == keccak256("ETH")) {
            if(leftToSpendInCampaignCurrency.add(1000) >= conversionAmountEthWEI && conversionAmountEthWEI.add(1000) >= minContributionAmountWei) {
                return true;
            }
        } else {
            uint rate = getRateFromExchange();
            uint conversionAmountCampaignCurrency = (conversionAmountEthWEI.mul(rate)).div(10**18);
            if(leftToSpendInCampaignCurrency.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18)) >= conversionAmountCampaignCurrency &&
                minContributionAmountWei <= conversionAmountCampaignCurrency.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18))
            ) {
                return true;
            }
        }
        return false;
    }

    // Updated
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



    function checkHowMuchUserCanContributeIncludingGoalAndMaxConversionAmount(
        address _converter
    )
    public
    view
    returns (uint)
    {
        //Get how much user can spend in terms of min/max contribution
        uint leftToSpendInCampaignCurrency = checkHowMuchUserCanSpend(_converter);
        if(endCampaignOnceGoalReached == true) {
            if(campaignRaisedIncludingPendingConversions.add(leftToSpendInCampaignCurrency) > campaignGoal) {
                return campaignGoal.sub(campaignRaisedIncludingPendingConversions);
            }
        }
        return leftToSpendInCampaignCurrency;
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


    /**
     * @notice Function to fetch stats for the address
     */
    function getAddressStatistic(
        address _address,
        bool plasma
    )
    internal
    view
    returns (bytes)
    {
        bytes32 state; // NOT-EXISTING AS CONVERTER DEFAULT STATE

        address eth_address = ethereumOf(_address);
        address plasma_address = plasmaOf(_address);

        if(_address == contractor) {
            return abi.encodePacked(0, 0, 0, false, false);
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


    function convertConversionAmountToCampaignCurrency(uint conversionAmount) internal view returns (uint) {
        if(keccak256(currency) != keccak256('ETH')) {
            uint rate = getRateFromExchange();
            return conversionAmount.mul(rate).div(10**18);
        }
        return conversionAmount;
    }

    /**
     * @notice Function to update total raised funds and validate conversion in terms of campaign goal
     */
    function updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(uint conversionAmountInCampaignCurrency) internal returns (bool) {
        uint newTotalRaisedFunds = campaignRaisedIncludingPendingConversions.add(conversionAmountInCampaignCurrency);
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
            require(campaignRaisedIncludingConversion <= campaignGoal.add(minContributionAmountWei)); //small GAP
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
        if(endCampaignOnceGoalReached == true && campaignRaisedIncludingPendingConversions.add(minContributionAmountWei) >= campaignGoal) {
            return true;
        }
        return false;
    }

    function getConstantInfo()
    public
    view
    returns (uint,uint,uint,uint,uint)
    {
        return (
            campaignStartTime,
            campaignEndTime,
            minContributionAmountWei,
            maxContributionAmountWei,
            campaignGoal
        );
    }
}
