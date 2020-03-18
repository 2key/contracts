import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

export default function checkConverterMetricTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {

  it(`should get converter metrics per campaign`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    expect(user).to.be.a('object');
    const storageMetric = user.converterMetrics;
    const metrics = await protocol[campaignContract].getConverterMetricsPerCampaign(
      campaignAddress, address);

    /**
     * totalLocked - conversions portions which not unlocked till now.
     * In tests is always zero because unlock dates are behind current date
     */
    expectEqualNumbers(metrics.totalLocked, 0);
    expectEqualNumbers(metrics.totalBought, storageMetric.totalBought);
    expectEqualNumbers(metrics.totalAvailable, storageMetric.totalAvailable);
    expectEqualNumbers(metrics.totalWithdrawn, storageMetric.totalWithdrawn)
  }).timeout(60000);
}
