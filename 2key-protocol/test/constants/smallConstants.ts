const {env} = process;

// 0.001 ETH is the debt for the registration
export const registrationDebt = 0.0001;

export const conversionStatuses = {
  cancelledByConverter: 'CANCELLED_BY_CONVERTER',
  pendingApproval: 'PENDING_APPROVAL',
  approved: 'APPROVED',
  executed: 'EXECUTED',
  rejected: 'REJECTED',
};

export const userStatuses = {
  pending: 'NOT_CONVERTER',
  approved: 'APPROVED',
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
  noReferralReward: 'NO_REFERRAL_REWARD',
};

/**
 * This rates should be set in the end of `TwoKeyExchangeRateContract` test or in the beginning of campaigns tests
 */
export const exchangeRates = {
  usd: 100,
  usdDai: 0.099,
  usd2Key: 0.06,
  dai: 0.99,
  tusd: 0.97
};

export const hedgeRate = 1000;

export const campaignTypes = {
  acquisition: 'TOKEN_SELL',
  donation: 'DONATION',
  cpc: 'CPC',
};


export const campaignTypeToInstance = {
  [campaignTypes.acquisition]: 'AcquisitionCampaign',
  [campaignTypes.donation]: 'DonationCampaign',
  [campaignTypes.cpc]: 'CPCCampaign',
};

export const feePercent = 0.02;

export const rpcUrls = [env.RPC_URL];
export const eventsUrls = [env.PLASMA_RPC_URL];
