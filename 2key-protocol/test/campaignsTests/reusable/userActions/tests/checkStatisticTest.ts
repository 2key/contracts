import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";

/**
 {
    amountConverterSpentETH: 0,
    referrerRewards: 1666.6666666666667,
    tokensBought: 0,
    isConverter: false,
    isReferrer: true,
    isJoined: true,
    username: 'gmail',
    fullName: '7YwD8IUQcly0KwM5Jc+IZw==',
    email: 'RY6B9WJVMQK0tajTtW3jWw==',
    ethereumOf: '0xf3c7641096bc9dc50d94c572bb455e56efc85412',
    converterState: 'NOT_CONVERTER'
  }
 */
// todo: add assertion or remove
export default function checkStatisticTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it(`should get statistics for ${userKey}`, async () => {
    const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    let stats = await protocol[campaignContract].getAddressStatistic(
      campaignAddress,
      address,
      '0x0000000000000000000000000000000000000000',
      {from: web3Address},
    );
    console.log(stats);
  }).timeout(60000);
}
