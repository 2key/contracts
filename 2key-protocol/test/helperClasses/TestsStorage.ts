import {availableTestCounters} from "../constants/storageConstants";

type availableCounters =
  availableTestCounters.approvedConversions
  | availableTestCounters.approvedConverters
  | availableTestCounters.campaignRaisedByNow
  | availableTestCounters.cancelledConversions
  | availableTestCounters.executedConversions
  | availableTestCounters.pendingConversions
  | availableTestCounters.pendingConverters
  | availableTestCounters.raisedFundsEthWei
  | availableTestCounters.raisedFundsFiatWei
  | availableTestCounters.rejectedConversions
  | availableTestCounters.rejectedConverters
  | availableTestCounters.tokensSold
  | availableTestCounters.totalBounty
  | availableTestCounters.uniqueConverters
;

const initialArrays = {
  pendingConverters: [],
  approvedConverters: [],
  rejectedConverters: [],
};

const initialCounters = {
  approvedConversions: 0,
  approvedConverters: 0,
  campaignRaisedByNow: 0,
  cancelledConversions: 0,
  executedConversions: 0,
  pendingConversions: 0,
  pendingConverters: 0,
  raisedFundsEthWei: 0,
  raisedFundsFiatWei: 0,
  rejectedConversions: 0,
  rejectedConverters: 0,
  tokensSold: 0,
  totalBounty: 0,
  uniqueConverters: 0,
};

class TestsStorage {

  private counters = {
    ...initialCounters
  };

  private arrays = {...initialArrays};

  private campaignObj = {
    campaignAddress: undefined,
  };

  private userData = {};

  incrementCounter(key: availableCounters){
    this.counters[key] = (this[key] || 0) + 1;
  }

  decrementCounter(key: availableCounters){
    this.counters[key] = (this[key] || 0) - 1;
  }

  getCounter(key: availableCounters){
    return this.counters[key];
  }

  arrayPush(key, value){
    if(!Array.isArray(this.arrays[key])){
      this.arrays[key] = [];
    }

    this.arrays[key].push(value);
  }

  arrayRemove(key, value){
    if(!Array.isArray(this.arrays[key])){
      return
    }

    this.arrays[key] = this.arrays[key].filter(
      (val) => (val !== value)
    );
  }

  getArray(key){
    return this.arrays[key];
  }

  set campaign(value){
    this.campaignObj = value;
  }

  get campaign(){
    return this.campaignObj;
  }

  get campaignAddress(){
    return this.campaignObj.campaignAddress;
  }

  setUserData(userKey, fieldKey, value){
    if(typeof this.userData[fieldKey] !== 'object'){
      this.userData[fieldKey] = {};
    }

    return this.userData[fieldKey] = value;
  }

  getUserData(userKey, fieldKey){
    return this.userData[fieldKey];
  }
}

export default TestsStorage;
