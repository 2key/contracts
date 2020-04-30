import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {hedgeRate} from "../../../../constants/smallConstants";
import {expect} from "chai";
import {promisify} from "../../../../../src/utils/promisify";

export default function hedgingEthTest(
  {
    userKey,
  }: functionParamsInterface,
) {
  it(`should hedging all available ether (${userKey})`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];

    const {balance: {ETH}} = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);
    const amountForHedge = parseFloat(ETH.toString());

    let txHash = await protocol.UpgradableExchange.startHedgingEth(
        amountForHedge,
        hedgeRate,
        address
    );

    await protocol.Utils.getTransactionReceiptMined(
      txHash
    );

    const upgradableExchangeBalanceAfter = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);

    expect(upgradableExchangeBalanceAfter.balance.ETH.toString()).to.be.eq('0');
  }).timeout(50000);
}
