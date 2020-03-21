import {IConversionObject,} from "../../src/acquisition/interfaces";
import {IConversion} from "../../src/donation/interfaces";
import {ICPCConversion} from "../../src/cpc/interfaces";

interface ITestConversion {
  readonly _id: number;
  _data: IConversionObject | IConversion | ICPCConversion;
  readonly id: number;

  state: string;
  data: IConversionObject | IConversion | ICPCConversion;
}

export default ITestConversion;
