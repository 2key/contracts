import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import getTwoKeyEconomyAddress from "../../../../helpers/getTwoKeyEconomyAddress";

export default function mainChainBalancesSyncTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should end campaign, reserve tokens, and rebalance rates as well`, async () => {

  }).timeout(60000);
}
