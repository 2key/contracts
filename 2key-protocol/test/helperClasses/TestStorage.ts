import {availableStorageArrays, availableStorageCounters} from "../constants/storageConstants";
import {IAcquisitionCampaignMeta} from "../../src/acquisition/interfaces";


class TestStorage {

  // todo: maybe counters can be totally replaced by arrays check getCounter usage after cleanup
  private counters = {};

  private arrays = {};

  private campaignObj: IAcquisitionCampaignMeta;

  private userData = {};

  incrementCounter(key) {
    this.counters[key] = (this[key] || 0) + 1;
  }

  decrementCounter(key) {
    this.counters[key] = (this[key] || 0) - 1;
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

  getArray(key) {
    return this.arrays[key];
  }

  set campaign(value: IAcquisitionCampaignMeta) {
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
