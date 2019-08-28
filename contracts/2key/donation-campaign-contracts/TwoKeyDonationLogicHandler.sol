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

    uint powerLawFactor;

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

        if(numberValues[8] == 1) {
            endCampaignOnceGoalReached = true;
        }

        contractor = _contractor;
        moderator = _moderator;
        currency = _currency;


        twoKeySingletonRegistry = _twoKeySingletonRegistry;
        twoKeyEventSource = getAddressFromRegistry("TwoKeyEventSource");
        twoKeyMaintainersRegistry = getAddressFromRegistry("TwoKeyMaintainersRegistry");
        twoKeyRegistry = getAddressFromRegistry("TwoKeyRegistry");

        ALLOWED_GAP = 1000000000000000;

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
        if(endCampaignOnceGoalReached == true && campaignRaisedAlready.add(minContributionAmountWei) >= campaignGoal) {
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
