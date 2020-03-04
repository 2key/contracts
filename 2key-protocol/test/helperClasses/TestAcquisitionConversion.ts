import {IConversionObject, IPurchaseInformation} from "../../src/acquisition/interfaces";
import {IConversion} from "../../src/donation/interfaces";
import {ICPCConversion} from "../../src/cpc/interfaces";
import {campaignTypes} from "../constants/smallConstants";
import ITestConversion from "../typings/ITestConversion";

class TestAcquisitionConversion implements ITestConversion{
  readonly _id: number;

  readonly _data:  IConversionObject;

  purchase: IPurchaseInformation;

  constructor(id: number, conversion: IConversionObject ) {
    this._id = id;
    this._data = conversion;
  }

  get id(){
    return this._id;
  }

  get state (){
    return this._data.state;
  }

  set state(val : string){
    this._data.state = val;
  }

  set data(newConversion: IConversionObject){
    Object.assign(this._data, newConversion);
  }

  get data(): IConversionObject{
    return {...this._data};
  }
}

export default TestAcquisitionConversion;
