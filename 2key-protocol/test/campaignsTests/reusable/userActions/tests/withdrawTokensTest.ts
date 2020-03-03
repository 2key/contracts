import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

export default function withdrawTokensTest(
  {
    storage,
    userKey,
    campaignContract,
    campaignData
  }: functionParamsInterface,
) {
  it('should withdraw tokens', async () => {
    const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);
    const executedConversions = user.executedConversions;

    expect(executedConversions.length).to.be.gt(0);

    const portionIndex = 0;

    const conversionIds = await protocol[campaignContract].getConverterConversionIds(
      campaignAddress, address, web3Address,
    );
    const conversion = executedConversions[0];
    const balanceBefore = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].withdrawTokens(
        campaignAddress,
        conversion.id,
        portionIndex,
        web3Address,
      )
    );

    const balanceAfter = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);
    const purchase = await protocol[campaignContract].getPurchaseInformation(campaignAddress, conversion.id, web3Address);
    const withdrawnContract = purchase.contracts[portionIndex];

    expectEqualNumbers(withdrawnContract.amount, balanceAfter - balanceBefore);
    expect(withdrawnContract.withdrawn).to.be.eq(true);

    conversion.purchase = purchase;
  }).timeout(60000);

}
