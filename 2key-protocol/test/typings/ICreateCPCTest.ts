import {ICreateCPC} from "../../src/cpc/interfaces";

interface ICreateCPCTest extends ICreateCPC{
  etherForRewards?: number;
  targetClicks?: number;
}

export default ICreateCPCTest;
