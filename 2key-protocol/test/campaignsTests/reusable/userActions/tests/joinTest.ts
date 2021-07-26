import functionParamsInterface from "../typings/functionParamsInterface";
import {campaignUserActions} from "../../../../constants/campaignUserActions";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {ipfsRegex} from "../../../../helpers/regExp";
import {incentiveModels} from "../../../../constants/smallConstants";

export default function joinTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    cut,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  if (!cut && campaignData.incentiveModel === incentiveModels.manual) {
    throw new Error(
      `${campaignUserActions.join} action required parameter missing for user ${userKey}`
    );
  }

  it(`should create a join link for ${userKey}`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const currentUser = storage.getUser(userKey);
    const refUser = storage.getUser(secondaryUserKey);

    const linkObject = await protocol[campaignContract].join(
      campaignAddress,
      address, {
        cut,
        referralLink: refUser.link.link,
        fSecret: refUser.link.fSecret,
      }
    );

    currentUser.cut = cut;
    currentUser.link = linkObject;
    currentUser.refUserKey = secondaryUserKey;

    expect(ipfsRegex.test(linkObject.link)).to.be.eq(true);
  }).timeout(10000);

  it(`should check is ${userKey} joined by ${secondaryUserKey} link`, async () => {
    const {protocol} = availableUsers[userKey];
    const user = storage.getUser(userKey);
    const {protocol: refProtocol} = availableUsers[user.refUserKey];
    const {campaignAddress, campaign: {contractor}} = storage;

    const joinedFrom = await protocol.PlasmaEvents.getJoinedFrom(
      campaignAddress,
      contractor,
      protocol.plasmaAddress,
    );

    expect(joinedFrom).to.eq(refProtocol.plasmaAddress)
  }).timeout(10000);
}
