import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";
import ITestConversion from "../../../../typings/ITestConversion";
import acquisitionOnly from "../checks/acquisitionOnly";

export default function withdrawTokensTest(
  {
    storage,
    userKey,
    campaignContract,
    campaignData
  }: functionParamsInterface,
) {
  acquisitionOnly(storage.campaignType);

  it('should withdraw tokens', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);
    const executedConversions = user.executedConversions;

    expect(executedConversions.length).to.be.gt(0);

    let portionIndex = 0;

    const conversion = executedConversions
      .find(
        (conversion: ITestConversion) => {
          if (!(conversion instanceof TestAcquisitionConversion)) {
            return true;
          }

          if (conversion instanceof TestAcquisitionConversion) {
            return Boolean(
              conversion.purchase.contracts
                .find(
                  (contract, contractIndex) => {
                    if (!contract.withdrawn) {
                      portionIndex = contractIndex;
                      return true;
                    }
                    return false;
                  },
                )
            );
          }
        }
      );

    expect(conversion).to.be.a('object');

    const balanceBefore = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].withdrawTokens(
        campaignAddress,
        conversion.id,
        portionIndex,
        address,
      )
    );

    const balanceAfter = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);
    const purchase = await protocol[campaignContract].getPurchaseInformation(campaignAddress, conversion.id, address);
    const withdrawnContract = purchase.contracts[portionIndex];

    expectEqualNumbers(withdrawnContract.amount, balanceAfter - balanceBefore);
    expect(withdrawnContract.withdrawn).to.be.eq(true);

    if (conversion instanceof TestAcquisitionConversion) {
      conversion.purchase = purchase;
    }
  }).timeout(60000);

}
