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
  /**
   * todo: add totalLocked assertion
   */
  it(`should get converter metrics per campaign`, async () => {
    const {protocol, address} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    expect(user).to.be.a('object');
    const storageMetric = user.converterMetrics;
    const metrics = await protocol[campaignContract].getConverterMetricsPerCampaign(
      campaignAddress, address);

    expectEqualNumbers(metrics.totalBought, storageMetric.totalBought);
    expectEqualNumbers(metrics.totalAvailable, storageMetric.totalAvailable);
    expectEqualNumbers(metrics.totalWithdrawn, storageMetric.totalWithdrawn)
  }).timeout(60000);
}
