import availableUsers from "../../constants/availableUsers";
import singletons from "../../../src/contracts/singletons";
import {vestingSchemas} from "../../constants/smallConstants";
import {TestIAcquisitionCampaign} from "../../typings/TestIAcquisitionCampaign";

const {protocol: deployerProtocol} = availableUsers.deployer;

export default function getCampaignData(
  {
    amount,
    campaignInventory,
    maxConverterBonusPercent,
    pricePerUnitInETHOrUSD,
    maxReferralRewardPercent,
    minContributionETHorUSD,
    maxContributionETHorUSD,
    campaignStartTime,
    campaignEndTime,
    acquisitionCurrency,
    twoKeyEconomy,
    isFiatOnly,
    isFiatConversionAutomaticallyApproved,
    vestingAmount,
    isKYCRequired,
    incentiveModel,
    tokenDistributionDate,
    numberOfVestingPortions,
    numberOfDaysBetweenPortions,
    bonusTokensVestingStartShiftInDaysFromDistributionDate,
    maxDistributionDateShiftInDays,
  }
): TestIAcquisitionCampaign {


  return {
    // helper data
    campaignInventory,
    amount,
    // Probably deploer address
    moderator: availableUsers.aydnep.web3.address,
    expiryConversion: 0, // For conversion cancellation from converter side
    // twoKeyEconomy or custom erc
    assetContractERC20: twoKeyEconomy,
    pricePerUnitInETHWei: deployerProtocol.Utils.toWei(pricePerUnitInETHOrUSD, 'ether'),
    currency: acquisitionCurrency, // ETH or USD (exchange contract working)
    // Start campaign details step

    // Campaign Goals
    campaignHardCapWEI: deployerProtocol.Utils.toWei((campaignInventory * pricePerUnitInETHOrUSD), 'ether'),
    campaignSoftCapWEI: deployerProtocol.Utils.toWei((campaignInventory * pricePerUnitInETHOrUSD), 'ether'),

    // End the contract once it reaches it's goal
    endCampaignWhenHardCapReached: true,

    // Campaign Bonus
    maxConverterBonusPercentWei: maxConverterBonusPercent, // 0 or > 0

    //
    /**
     * Currencies select
     *
     * true - if selected fiat
     * true || false
     */
    isFiatOnly,
    /**
     * true - no need bank details
     *
     * true || false
     */
    isFiatConversionAutomaticallyApproved,

    // Campaign Dates
    campaignStartTime,
    campaignEndTime,

    // Tokens Lockup
    // should be date
    tokenDistributionDate,
    maxDistributionDateShiftInDays, // what is this?
    // total amount divider, how payments will be
    numberOfVestingPortions,
    // Interval between payments in days
    numberOfDaysBetweenPortions,
    // only BONUS, when bonus payments payouts start in days
    bonusTokensVestingStartShiftInDaysFromDistributionDate,

    // with bonus or without, BASE_AND_BONUS or BONUS
    vestingAmount,

    // Advanced options - Participant details

    // Participation Limits
    minContributionETHWei: deployerProtocol.Utils.toWei(minContributionETHorUSD, 'ether'), // min === max or min < max
    maxContributionETHWei: deployerProtocol.Utils.toWei(maxContributionETHorUSD, 'ether'),
    /**
     * Ask for Identity Verification?
     * true - required contractor approve for each conversion
     *
     * true || false
     */
    isKYCRequired,
    // End campaign details step

    //Referral Reward
    maxReferralRewardPercentWei: maxReferralRewardPercent, // 0 or > 0

    // Only Participants can join the Referral program
    mustConvertToReferr: false,
    /**
     *
     * NOBONUS - maxReferralRewardPercentWei === 0
     * MANUAL - manual checked
     * vanilla types:
     * EQUAL -
     * EQUAL3X -
     * GROWING -
     */
    incentiveModel,
    // Limit the number of invites per referrer
    // number or inlimited
    referrerQuota: undefined,
    // Limit the number of users to start a referral chain
    // number or inlimited
    totalSupplyArcs: undefined,
  };
}
