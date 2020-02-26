// 0.001 ETH is the debt for the registration
export const registrationDebt = 0.0001;

export const conversionStatuses = {
  cancelledByConverter: 'CANCELLED_BY_CONVERTER',
  pendingApproval: 'PENDING_APPROVAL',
  approved: 'APPROVED',
  executed: 'EXECUTED',
  rejected: 'REJECTED',
};

export const vestingSchemas = {
  bonus: 'BONUS',
  baseAndBonus: 'BASE_AND_BONUS',
};

export const incentiveModels = {
  manual: 'MANUAL',
  vanillaAverage: 'VANILLA_AVERAGE',
  vanillaAverageLast3x: 'VANILLA_AVERAGE_LAST_3X',
  vanillaPowerLaw: 'VANILLA_POWER_LAW',
  noReferalReward: 'NO_REFERRAL_REWARD',
};

/**
 * This rates should be set in the end of `TwoKeyExchangeRateContract` test or in the beginning of campaigns tests
 */
export const exchangeRates = {
  usd: 100,
  usdDai: 0.099,
};

export const hedgeRate = 1000;
