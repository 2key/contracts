import {IReferralLink} from "../../src/acquisition/interfaces";
import {conversionStatuses, userStatuses} from "../constants/smallConstants";
import ITestConversion from "../typings/ITestConversion";
import TestDonationConversion from "./TestDonationConversion";
import TestAcquisitionConversion from "./TestAcquisitionConversion";

class TestUser {

  readonly _id: string;

  private refLink?: IReferralLink;

  private conversions: Array<ITestConversion> = [];

  private statusVal: string;

  private refRewardsPerConversion: { [key: number]: number } = {};

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

  addConversion(conversion: ITestConversion) {
    this.conversions.push(conversion);
  }

  addRefReward(conversionId: number, amount: number): void {
    this.refRewardsPerConversion[conversionId] = amount;
  }

  get id() {
    return this._id;
  }

  get referrerReward(): number {
    return Object.values(this.refRewardsPerConversion)
      .reduce(
        (accum: number, refReward: number): number => {
          return accum + refReward;
        },
        0
      );
  }

  set status(val: string) {
    if (val === userStatuses.rejected) {
      this.conversions = this.conversions.map((conversion: ITestConversion) => {
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

  get allConversions(): Array<ITestConversion> {
    return this.conversions;
  }

  get pendingConversions(): Array<ITestConversion> {
    return this.conversions
      .filter((conversion: ITestConversion) => (conversion.state === conversionStatuses.pendingApproval));
  }

  get approvedConversions(): Array<ITestConversion> {
    return this.conversions
      .filter((conversion: ITestConversion) => (conversion.state === conversionStatuses.approved));
  }

  get executedConversions(): Array<ITestConversion> {
    return this.conversions
      .filter((conversion: ITestConversion) => (conversion.state === conversionStatuses.executed));
  }

  get rejectedConversions(): Array<ITestConversion> {
    return this.conversions
      .filter((conversion: ITestConversion) => (conversion.state === conversionStatuses.rejected));
  }

  get canceledConversions(): Array<ITestConversion> {
    return this.conversions.filter((conversion: ITestConversion) => (conversion.state === conversionStatuses.cancelledByConverter))
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
          if (conversion instanceof TestAcquisitionConversion) {
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
          }
        },
      );

    return metric;
  }

  get executedConversionsTotal(): number {
    return this.executedConversions.reduce(
      (accum: number, conversion: ITestConversion): number => {
        if (conversion instanceof TestAcquisitionConversion) {
          accum += (conversion.data.bonusTokenUnits + conversion.data.baseTokenUnits);
        } else if (conversion instanceof TestDonationConversion) {
          accum += conversion.data.tokensBought;
        }

        return accum;
      },
      0,
    )
  }
}

export default TestUser;
