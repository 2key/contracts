import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {campaignTypes, incentiveModels} from "../../../../constants/smallConstants";
import {expectEqualNumbers, rewardCalc} from "../../../../helpers/numberHelpers";

export default function checkManualCutsChainTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  if (campaignData.incentiveModel !== incentiveModels.manual) {
    throw new Error('Unacceptable test');
  }

  it(`should check correct referral value after visit by ${userKey}`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const refUser = storage.getUser(secondaryUserKey);

    let maxReward = await protocol[campaignContract].getEstimatedMaximumReferralReward(
      campaignAddress,
      address, refUser.link.link, refUser.link.fSecret,
    );

    /**
     * on this stage user didn't select link owner as referral
     */
    const cutChain = [...storage.getReferralsForUser(refUser), refUser]
      .reverse()
      .map(({cut}) => cut / 100);

    const initialPercent = storage.campaignType === campaignTypes.donation
      ? campaignData.maxReferralRewardPercent
      : campaignData.maxReferralRewardPercentWei;
    console.log(maxReward)
    console.dir({initialPercent, cutChain})
    console.log(rewardCalc(initialPercent, cutChain))

    expectEqualNumbers(maxReward, rewardCalc(initialPercent, cutChain));
  }).timeout(60000);
}
