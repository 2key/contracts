import {ICreateCPCNoRewards} from "../../src/cpcNoRewards/interfaces";

interface ICreateCPCNoRewardsTest extends ICreateCPCNoRewards{
    etherForRewards?: number;
    targetClicks?: number;
}

export default ICreateCPCNoRewardsTest;
