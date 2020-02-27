
import {IAcquisitionCampaignMeta} from "../../src/acquisition/interfaces";
import {campaignTypes} from "../constants/smallConstants";
import {IDonationMeta} from "../../src/donation/interfaces";


class TestStorage {

  // todo: maybe counters can be totally replaced by arrays check getCounter usage after cleanup
  counters = {};

  arrays = {};

  campaignObj: IAcquisitionCampaignMeta | IDonationMeta;

  userData = {};

  contractorKey: string = undefined;

  campaignType: string = undefined;

  constructor(contractorKey, campaignType = campaignTypes.acquisition) {
    this.contractorKey = contractorKey;
    this.campaignType = campaignType;
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
