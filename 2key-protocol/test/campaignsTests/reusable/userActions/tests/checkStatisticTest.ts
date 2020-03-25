import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {userStatuses} from "../../../../constants/smallConstants";


export default function checkStatisticTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it(`should get statistics for ${userKey}`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    const stats = await protocol[campaignContract].getAddressStatistic(
      campaignAddress,
      address,
      '0x0000000000000000000000000000000000000000',
      {from: address},
    );
    const {isJoined, converterState, tokensBought} = stats;

    console.log('Converter state is: ' + converterState);

    expect(converterState).to.be
      .eq(
        user.status
      );
    expect(isJoined).to.be.eq(Boolean(user.link || user.allConversions.length));
    expect(tokensBought).to.be.eq(user.executedConversionsTotal);
  }).timeout(60000);
}
