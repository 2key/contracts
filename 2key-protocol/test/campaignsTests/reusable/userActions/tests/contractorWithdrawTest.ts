import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {campaignTypes} from "../../../../constants/smallConstants";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";

export default function contractorWithdrawTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  if (storage.campaignType === campaignTypes.cpc) {
    it('should contractor withdraw unspent budget', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      // @ts-ignore
      const {campaign: {campaignAddressPublic}} = storage;

      let campaignBalanceBefore = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy._address, campaignAddressPublic);
      let contractorBalanceBefore = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy._address, address);

      await protocol.CPCCampaign.contractorWithdraw(campaignAddressPublic, address);

      await new Promise(resolve => setTimeout(resolve, 5000));

      let contractorBalanceAfter = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy._address, address);

      const campaignBalanceAfter = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy._address, campaignAddressPublic);

      expectEqualNumbers(contractorBalanceAfter, contractorBalanceBefore + campaignBalanceBefore);
      expect(campaignBalanceAfter).to.be.eq(0);
    }).timeout(10000)
  } else {
    it('should contractor withdraw his earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);

      const contractorBalanceBefore = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
      );

      const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

      if (userDeptsBefore > 0) {
        const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
        expect(userDeptsAfter).to.be.lt(userDeptsBefore);
      }

      expectEqualNumbers(
        Number.parseFloat(
          contractorBalanceBefore.available
        ),
        contractorBalance.available +  contractorBalanceBefore.available
      );

      expect(contractorBalance.available).to.be.eq(0);
    }).timeout(10000);
  }
}
