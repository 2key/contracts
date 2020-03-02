import {IConversionObject, IPurchaseInformation, IReferralLink} from "../../src/acquisition/interfaces";
import {conversionStatuses, userStatuses} from "../constants/smallConstants";
import BigNumber from "bignumber.js";

interface IConversionTests extends IConversionObject {
  id: number;
  purchase?: IPurchaseInformation
}

class TestUser {

  private _id: string;

  private refLink?: IReferralLink;

  private conversions: Array<IConversionTests> = [];

  private statusVal: string;

  /**
   * Has affect only for manual incentiveModel
   */
  cut: number;
  /**
   * Referral user key
   */
  refUserKey: string;

  constructor(id: string, status?: string) {
    this._id = id;
    this.statusVal = status;
  }

  addConversion(id: number, conversion: IConversionTests) {
    conversion.id = id;
    this.conversions.push(conversion);
  }

  get id() {
    return this._id;
  }

  set status(val: string) {
    if (val === userStatuses.rejected) {
      this.conversions = this.conversions.map((conversion: IConversionTests) => {
        conversion.state = conversionStatuses.rejected;
        return conversion;
      })
    }

    this.statusVal = val;
  }

  get status(): string {
    return this.statusVal;
  }

  set link(link: IReferralLink) {
    if (this.refLink) {
      return;
    }

    this.refLink = link;
  }

  get link(): IReferralLink {
    return this.refLink;
  }

  get allConversions(): Array<IConversionTests> {
    return this.conversions;
  }

  get pendingConversions(): Array<IConversionTests> {
    return this.conversions
      .filter((conversion: IConversionTests) => (conversion.state === conversionStatuses.pendingApproval));
  }

  get approvedConversions(): Array<IConversionTests> {
    return this.conversions
      .filter((conversion: IConversionTests) => (conversion.state === conversionStatuses.approved));
  }

  get executedConversions(): Array<IConversionTests> {
    return this.conversions
      .filter((conversion: IConversionTests) => (conversion.state === conversionStatuses.executed));
  }

  get rejectedConversions(): Array<IConversionTests> {
    return this.conversions
      .filter((conversion: IConversionTests) => (conversion.state === conversionStatuses.rejected));
  }

  get canceledConversions(): Array<IConversionTests> {
    return this.conversions.filter((conversion: IConversionTests) => (conversion.state === conversionStatuses.cancelledByConverter))
  }

  get referralsReward(): number {
    return this.executedConversions
      .reduce(
        (accum: number, {maxReferralReward2key}) => {
          accum += maxReferralReward2key;
          return accum
        },
        0,
      );
  }

  get converterMetrics() {
    const metric = {
      totalBought: 0,
      totalAvailable: 0,
      totalLocked: 0,
      totalWithdrawn: 0,
    };

    this.executedConversions
      .forEach(
        (conversion) => {
          metric.totalBought += conversion.purchase.totalTokens;

          conversion.purchase.contracts
            .forEach(
              (contract) => {
                if (contract.withdrawn) {
                  metric.totalWithdrawn += contract.amount;
                } else {
                  metric.totalAvailable += contract.amount;
                }
              },
            );
        },
      );

    return metric;
  }
}

export default TestUser;
