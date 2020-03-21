import {incentiveModels} from "../../constants/smallConstants";
import TestUser from "../../helperClasses/TestUser";

export default function calculateReferralRewards(
  incentiveModel, referrals: Array<TestUser>,
  totalReward: number,
): { [key: string]: number } {
  const rewards = {};
  const reversedReferrals = [...referrals].reverse();

  switch (incentiveModel) {
    case incentiveModels.manual:
      reversedReferrals
        .reduce((leftAmount, user, index) => {
          /**
           * If last user get all available after all cuts
           */
          if (index !== referrals.length - 1) {
            rewards[user.id] = leftAmount * user.cut / 100;
          } else {
            rewards[user.id] = leftAmount;
          }

          return leftAmount - rewards[user.id];
        }, totalReward);
      break;
    case incentiveModels.vanillaAverage:
      const vanillaAverageReward = totalReward / referrals.length;
      referrals.forEach(
        ({id}) => {
          rewards[id] = vanillaAverageReward
        }
      );
      break;
    case incentiveModels.vanillaAverageLast3x:
      const vanillaAverageLast3xBaseReward = totalReward / (referrals.length + 2);

      referrals.forEach(
        ({id}, index) => {
          if (index === 0) {
            rewards[id] = vanillaAverageLast3xBaseReward * 3
          } else {
            rewards[id] = vanillaAverageLast3xBaseReward
          }
        }
      );
      break;
    case incentiveModels.vanillaPowerLaw:
      const powerLawFactor = 2;
      const x = calculateX(totalReward, referrals.length, powerLawFactor);

      for (let i = 0; i < referrals.length; i++) {
        const user = reversedReferrals[referrals.length - (i + 1)];

        rewards[user.id] = x / (powerLawFactor ** i);
      }
      break;
    case incentiveModels.noReferralReward:
      referrals.forEach((user) => {
        rewards[user.id] = 0;
      });
      break;
    default:
      throw new Error('Unknown incentive model');
  }

  return rewards;
}

function calculateX(
  sumWei: number,
  numberOfElements: number,
  factor: number
): number {
  let a = 1;
  let sumOfFactors = 1;

  for (let i = 1; i < numberOfElements; i++) {
    a *= factor;
    sumOfFactors += a;
  }

  return sumWei * a / sumOfFactors;
}
