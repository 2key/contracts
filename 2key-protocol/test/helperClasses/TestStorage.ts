import {IAcquisitionCampaignMeta} from "../../src/acquisition/interfaces";
import {campaignTypes, userStatuses} from "../constants/smallConstants";
import {IDonationMeta} from "../../src/donation/interfaces";
import TestUser from "./TestUser";
import {userIds} from "../constants/availableUsers";
import ITestConversion from "../typings/ITestConversion";
import TestAcquisitionConversion from "./TestAcquisitionConversion";
import TestDonationConversion from "./TestDonationConversion";
import TestCPCConversion from "./TestCPCConversion";


class TestStorage {
  private users: { [key: string]: TestUser } = {};

  private campaignObj: IAcquisitionCampaignMeta | IDonationMeta;

  contractorKey: string = undefined;

  campaignType: string = undefined;

  constructor(contractorKey, campaignType: string = campaignTypes.acquisition, withKyc: boolean = false) {
    this.contractorKey = contractorKey;

    const {
      [userIds.deployer]: deployer,
      [userIds.guest]: guest,
      ...usersForTest
    } = userIds;

    this.campaignType = campaignType;

    this.users = Object.values(usersForTest).reduce(
      (accum, userId: string) => {
        return {
          ...accum,
          [userId]: new TestUser(
            userId,
            withKyc ? userStatuses.pending : userStatuses.approved,
          ),
        };
      },
      {},
    );
  }

  getUser(userKey: string): TestUser {
    return this.users[userKey];
  }

  get pendingConversions(): Array<ITestConversion> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<ITestConversion>, user: TestUser) => {
          return [...accum, ...user.pendingConversions];
        },
        [],
      )
  }

  get approvedConversions(): Array<ITestConversion> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<ITestConversion>, user: TestUser) => {
          return [...accum, ...user.approvedConversions];
        },
        [],
      )
  }

  get executedConversions(): Array<ITestConversion> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<ITestConversion>, user: TestUser) => {
          return [...accum, ...user.executedConversions];
        },
        [],
      )
  }

  get rejectedConversions(): Array<ITestConversion> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<ITestConversion>, user: TestUser) => {
          return [...accum, ...user.rejectedConversions];
        },
        [],
      )
  }

  get canceledConversions(): Array<ITestConversion> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<ITestConversion>, user: TestUser) => {
          return [...accum, ...user.canceledConversions];
        },
        [],
      )
  }

  set campaign(value: IAcquisitionCampaignMeta | IDonationMeta) {
    this.campaignObj = value;
  }

  get campaign() {
    return this.campaignObj;
  }

  get campaignAddress() {
    return this.campaignObj.campaignAddress;
  }

  get allUsers() {
    return this.users
  }

  get converters() {
    return Object.values(this.users).filter(
      (user) => (user.refUserKey && user.allConversions.length)
    );
  }

  get pendingUsers() {
    return this.converters.filter(({status}) => status === userStatuses.pending);
  }

  get approvedUsers() {
    return this.converters.filter(({status}) => status === userStatuses.approved);
  }

  get rejectedUsers() {
    return this.converters.filter(({status}) => status === userStatuses.rejected);
  }

  get tokensSold(): number {
    return this.executedConversions
      .reduce(
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

  get totalBounty(): number {
    return this.executedConversions
      .reduce(
        (accum: number, conversion: ITestConversion): number => {
          if (
            conversion instanceof TestAcquisitionConversion
            || conversion instanceof TestDonationConversion
          ) {
            accum += conversion.data.maxReferralReward2key;
          } else if (conversion instanceof TestCPCConversion) {
            accum += conversion.data.bountyPaid;
          }

          return accum;
        },
        0,
      )
  }

  // get raisedFundsEthWei(): number {
  //   return this.executedConversions
  //     .reduce(
  //       (accum: number, conversion: ITestConversion): number => {
  //         accum += conversion.conversionAmount;
  //
  //         return accum;
  //       },
  //       0,
  //     );
  // }

  getReferralsForUser(user: TestUser): Array<TestUser> {
    const referrals = [];

    for (
      let referral = this.getUser(user.refUserKey);
      referral.refUserKey;
      referral = this.getUser(referral.refUserKey)
    ) {
      referrals.push(referral);
    }

    return referrals;
  }
}

export default TestStorage;
