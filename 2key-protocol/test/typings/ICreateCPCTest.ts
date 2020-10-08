import {ICreateCPC} from "../../src/cpc/interfaces";

interface ICreateCPCTest extends ICreateCPC{
  bountyPerConversionUSD?: number;
  etherForRewards?: number;
  targetClicks?: number;
  bountyPerConversion?:number;
}

export default ICreateCPCTest;
