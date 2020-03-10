import {campaignTypes} from "../../../../constants/smallConstants";

export default function cpcOnly(campaignType:string){
  if(campaignType !== campaignTypes.cpc){
    throw new Error('Method allowed only for cpc campaigns');
  }
}
