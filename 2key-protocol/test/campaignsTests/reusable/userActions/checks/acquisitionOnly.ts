import {campaignTypes} from "../../../../constants/smallConstants";

export default function acquisitionOnly(campaignType:string){
  if(campaignType !== campaignTypes.acquisition){
    throw new Error('Method allowed only for cpc campaigns');
  }
}
