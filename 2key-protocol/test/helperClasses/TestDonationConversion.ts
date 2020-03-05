import {IConversion} from "../../src/donation/interfaces";
import ITestConversion from "../typings/ITestConversion";

class TestDonationConversion implements ITestConversion{
  readonly _id: number;

  readonly _data:  IConversion;

  constructor(id: number, conversion: IConversion ) {
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

  get data(): IConversion{
    return {...this._data};
  }

  set data(newConversion: IConversion){
    Object.assign(this._data, newConversion);
  }
}

export default TestDonationConversion;

