import {IConversionObject, IReferralLink} from "../../src/acquisition/interfaces";
import {conversionStatuses} from "../constants/smallConstants";

class TestUser{

  private id: string;

  private refLink?: IReferralLink;

  private conversions: Array<IConversionObject> = [];

  private statusVal: string;

  /**
   * Has affect only for manual incentiveModel
   */
  cut: number;
  /**
   * Referral user key
   */
  refUserKey: string;

  constructor(id: string, status?: string) {
    this.id = id;
    this.statusVal = status;
  }

  addConversion (conversion: IConversionObject){
    this.conversions.push(conversion);
  }

  set status (val: string){
    this.statusVal = val;
  }

  get status (): string{
    return this.statusVal;
  }

  set link(link: IReferralLink){
    if(this.refLink){
      return;
    }

    this.refLink = link;
  }

  get link():IReferralLink{
    return this.refLink;
  }

  get pendingConversions(): Array<IConversionObject>{
    return this.conversions.filter((conversion: IConversionObject) => (conversion.state === conversionStatuses.pendingApproval))
  }

  get approvedConversions(): Array<IConversionObject>{
    return this.conversions.filter((conversion: IConversionObject) => (conversion.state === conversionStatuses.approved))
  }

  get executedConversions(): Array<IConversionObject>{
    return this.conversions.filter((conversion: IConversionObject) => (conversion.state === conversionStatuses.executed))
  }

  get rejectedConversions(): Array<IConversionObject>{
    return this.conversions.filter((conversion: IConversionObject) => (conversion.state === conversionStatuses.rejected))
  }

  get canceledConversions(): Array<IConversionObject>{
    return this.conversions.filter((conversion: IConversionObject) => (conversion.state === conversionStatuses.cancelledByConverter))
  }

}

export default TestUser;
