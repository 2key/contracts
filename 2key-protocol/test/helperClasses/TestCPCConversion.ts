import {IConversionObject} from "../../src/acquisition/interfaces";
import {IConversion} from "../../src/donation/interfaces";
import {ICPCConversion} from "../../src/cpc/interfaces";
import {campaignTypes} from "../constants/smallConstants";
import ITestConversion from "../typings/ITestConversion";

class TestCPCConversion implements ITestConversion{
  readonly _id: number;

  readonly _data:  ICPCConversion;

  constructor(id: number, conversion: ICPCConversion) {
    this._id = id;
    this._data = conversion;
  }

  get id(){
    return this._id;
  }

  get state (){
    return this._data.conversionState;
  }

  set state(val : string){
    this._data.conversionState = val;
  }

  get data(): ICPCConversion{
    return {...this._data};
  }

  set data(newConversion: ICPCConversion){
    Object.assign(this._data, newConversion);
  }
}

export default TestCPCConversion;
