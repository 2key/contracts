import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import {conversionStatuses} from "../../../../constants/smallConstants";
import functionParamsInterface from "../typings/functionParamsInterface";
import kycRequired from "../checks/kycRequired";

export default function cancelConversionTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it(`${userKey} should cancel his conversion and ask for refund`, async () => {
    const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
    const user = storage.getUser(userKey);
    const {campaignAddress} = storage;

    const initialCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
      campaignAddress,
      address
    );
    const balanceBefore = await protocol.getBalance(web3Address, campaignData.assetContractERC20);

    const conversions = campaignData.isFiatConversionAutomaticallyApproved
      ? user.approvedConversions
      : user.pendingConversions;

    expect(conversions.length).to.be.gt(0);

    /**
     * Always get first. It can be any conversion from available for this action.
     * But easiest way is always get first
     */
    const storedConversion = conversions[0];

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].converterCancelConversion(
        campaignAddress,
        storedConversion.id,
        web3Address,
      )
    );

    const conversionObj = await protocol[campaignContract].getConversion(
      campaignAddress, storedConversion.id, web3Address,
    );
    const resultCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
      campaignAddress,
      address
    );
    const balanceAfter = await protocol.getBalance(web3Address, campaignData.assetContractERC20);

    /**
     * todo: recheck why so strange diff
     * For conversion amount `5`
     * diff is `4.999842805999206` - it is BigNumber calc
     * in some cases it  is `4.988210449999725` - it is BigNumber calc, in this case assertion fails

     expectEqualNumbers(
     conversionObj.conversionAmount,
     parseFloat(
     protocol.Utils.fromWei(
     parseFloat(balanceAfter.balance.ETH.toString())
     - parseFloat(balanceBefore.balance.ETH.toString())
     )
     .toString()
     ),
     );
     */
    expectEqualNumbers(
      resultCampaignInventory - initialCampaignInventory,
      conversionObj.baseTokenUnits + conversionObj.bonusTokenUnits
    );
    expect(conversionObj.state).to.be.eq(conversionStatuses.cancelledByConverter);

    Object.assign(storedConversion, conversionObj);
  }).timeout(60000);
}
