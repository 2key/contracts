import {campaignTypes} from "../../../../constants/smallConstants";

export default function donationOnly(campaignType:string){
  if(campaignType !== campaignTypes.donation){
    throw new Error('Method allowed only for donation campaigns');
  }
}
