import {IAcquisitionCampaign} from "../../src/acquisition/interfaces";

export interface TestIAcquisitionCampaign extends IAcquisitionCampaign{
  campaignInventory: number,
  amount: number,
}

