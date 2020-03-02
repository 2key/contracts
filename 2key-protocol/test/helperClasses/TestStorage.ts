import {IAcquisitionCampaignMeta, IConversionObject} from "../../src/acquisition/interfaces";
import {campaignTypes, userStatuses} from "../constants/smallConstants";
import {IDonationMeta} from "../../src/donation/interfaces";
import TestUser from "./TestUser";
import {userIds} from "../constants/availableUsers";


class TestStorage {
  private users: { [key: string]: TestUser } = {};

  // todo: maybe counters can be totally replaced by arrays check getCounter usage after cleanup
  counters = {};

  arrays = {};

  campaignObj: IAcquisitionCampaignMeta | IDonationMeta;

  userData = {};

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

  get pendingConversions(): Array<IConversionObject> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<IConversionObject>, user: TestUser) => {
          return [...accum, ...user.pendingConversions];
        },
        [],
      )
  }

  get approvedConversions(): Array<IConversionObject> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<IConversionObject>, user: TestUser) => {
          return [...accum, ...user.approvedConversions];
        },
        [],
      )
  }

  get executedConversions(): Array<IConversionObject> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<IConversionObject>, user: TestUser) => {
          return [...accum, ...user.executedConversions];
        },
        [],
      )
  }

  get rejectedConversions(): Array<IConversionObject> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<IConversionObject>, user: TestUser) => {
          return [...accum, ...user.rejectedConversions];
        },
        [],
      )
  }

  get canceledConversions(): Array<IConversionObject> {
    return Object.values(this.users)
      .reduce(
        (accum: Array<IConversionObject>, user: TestUser) => {
          return [...accum, ...user.canceledConversions];
        },
        [],
      )
  }

  counterIncrease(key, amount = 1) {
    this.counters[key] = (this[key] || 0) + amount;
  }

  counterDecrease(key, amount = 1) {
    this.counters[key] = (this[key] || 0) - amount;
  }

  getCounter(key) {
    return this.counters[key];
  }

  arrayPush(key, value) {
    if (!Array.isArray(this.arrays[key])) {
      this.arrays[key] = [];
    }

    this.arrays[key].push(value);
  }

  arrayRemove(key, value) {
    if (!Array.isArray(this.arrays[key])) {
      return
    }

    this.arrays[key] = this.arrays[key].filter(
      (val) => (val !== value)
    );
  }

  getArray(key): [] {
    return this.arrays[key] || [];
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

  setUserData(userKey, fieldKey, value) {
    if (typeof this.userData[userKey] !== 'object') {
      this.userData[userKey] = {};
    }

    return this.userData[userKey][fieldKey] = value;
  }

  getUserData(userKey, fieldKey) {
    return this.userData[userKey][fieldKey];
  }
}

export default TestStorage;
