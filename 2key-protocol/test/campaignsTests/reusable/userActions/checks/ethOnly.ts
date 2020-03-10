import {campaignTypes} from "../../../../constants/smallConstants";

export default function ethOnly(isFiatOnly:string){
  if(isFiatOnly){
    throw new Error('Method allowed only for eth campaigns');
  }
}
