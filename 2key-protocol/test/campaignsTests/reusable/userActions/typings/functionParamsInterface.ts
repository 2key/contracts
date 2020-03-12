import TestStorage from "../../../../helperClasses/TestStorage";

export default interface functionParamsInterface {
  storage: TestStorage,
  userKey: string,
  campaignData: any,
  campaignContract: string,

  expectError?: boolean,
  secondaryUserKey?: string,
  cut?: number,
  contribution?: number,
}
