import functionParamsInterface from "../typings/functionParamsInterface";
import {campaignUserActions} from "../../../constants/constants";
import availableUsers from "../../../../constants/availableUsers";
import fiatOnly from "../checks/fiatOnly";

export default function createOfflineConversionTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    contribution,
    campaignContract,
    campaignData,
  }: functionParamsInterface,
) {
  fiatOnly(campaignData.isFiatOnly);

  if (!contribution) {
    throw new Error(
      `${campaignUserActions.joinAndConvert} action required parameter missing for user ${userKey}`
    );
  }
  // todo: what should we check here
  it('should create an offline(fiat) conversion', async () => {
    const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
    const {link: refLink} = storage.getUser(secondaryUserKey);
    const {campaignAddress} = storage;

    const signature = await protocol[campaignContract].getSignatureFromLink(
      refLink.link, protocol.plasmaAddress, refLink.fSecret);

    const conversionIdsBefore = await protocol[campaignContract].getConverterConversionIds(
      campaignAddress, address, web3Address);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].convertOffline(
        campaignAddress, signature, web3Address, web3Address,
        contribution,
      )
    );
    const conversionIdsAfter = await protocol[campaignContract].getConverterConversionIds(
      campaignAddress, address, web3Address);

    console.log({conversionIdsBefore, conversionIdsAfter});
  }).timeout(60000);

}
