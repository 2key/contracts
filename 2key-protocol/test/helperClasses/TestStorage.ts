import {IAcquisitionCampaignMeta} from "../../src/acquisition/interfaces";
import {campaignTypes, conversionStatuses, userStatuses} from "../constants/smallConstants";
import {IDonationMeta} from "../../src/donation/interfaces";
import TestUser from "./TestUser";
import {userIds} from "../constants/availableUsers";
import ITestConversion from "../typings/ITestConversion";
import TestAcquisitionConversion from "./TestAcquisitionConversion";
import TestDonationConversion from "./TestDonationConversion";
import TestCPCConversion from "./TestCPCConversion";
import calculateReferralRewards from "../helpers/calculateReferralRewards";
import {ICPCMeta} from "../../src/cpc/interfaces";


class TestStorage {
  readonly requireApprove: Boolean;

  private users: { [key: string]: TestUser } = {};

  private campaignObj: IAcquisitionCampaignMeta | IDonationMeta| ICPCMeta;

  contractorKey: string = undefined;

  campaignType: string = undefined;

  constructor(contractorKey, campaignType: string = campaignTypes.acquisition, requireApprove: boolean = false) {
    this.contractorKey = contractorKey;

    const {
      [userIds.guest]: guest,
      ...usersForTest
    } = userIds;

    this.requireApprove = requireApprove;

    this.campaignType = campaignType;

    this.users = Object.values(usersForTest).reduce(
      (accum, userId: string) => {
        return {
          ...accum,
          [userId]: new TestUser(
            userId,
            requireApprove ? userStatuses.pending : userStatuses.approved,
          ),
        };
      },
      {},
    );
  }

  /**
   * Method should process each changes on any conversion
   * Ideally should be implemented with event handler from the user and store campaign data for usage
   * For now switch to reject status is skip because it sets inside user object
   * @param owner
   * @param conversion
   * @param incentiveModel
   */
  processConversion(owner: TestUser, conversion: ITestConversion, incentiveModel: string) {
    if (conversion.state === conversionStatuses.executed) {
      this.assignConversionRefRewardsToUsers(owner, conversion, incentiveModel);
    }
  }

  /**
   * Method calculate referral rewards for users when conversion executed
   * @param owner
   * @param conversion
   * @param incentiveModel
   */
  private assignConversionRefRewardsToUsers(owner: TestUser, conversion: ITestConversion, incentiveModel: string) {
    if(conversion.state !== conversionStatuses.executed){
      return;
    }

    const referrals = this.getReferralsForUser(owner);
    let conversionReward = 0;

    if (
      conversion instanceof TestAcquisitionConversion
      || conversion instanceof TestDonationConversion
    ) {
      conversionReward = conversion.data.maxReferralReward2key;
    } else if (conversion instanceof TestCPCConversion){
      conversionReward = conversion.data.bountyPaid;
    }

    if (!conversionReward) {
      return;
    }

    const rewardsPerUser = calculateReferralRewards(incentiveModel, referrals, conversionReward);

    Object.keys(rewardsPerUser).forEach((userKey: string) => {
      const user = this.getUser(userKey);

      user.addRefReward(conversion.id, rewardsPerUser[userKey]);
    })
  }

  addUser(userId){
    this.users[userId] = new TestUser(
      userId,
      this.requireApprove ? userStatuses.pending : userStatuses.approved,
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

  set campaign(value: IAcquisitionCampaignMeta | IDonationMeta| ICPCMeta) {
    this.campaignObj = value;
  }

  get campaign() {
    return this.campaignObj;
  }

  get campaignAddress() {
    return this.campaignObj.campaignAddress;
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

  get executedConversionsTotal(): number {
    return this.approvedUsers
      .reduce(
        (accum: number, user: TestUser): number => {
          accum += user.executedConversionsTotal;

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
