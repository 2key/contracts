import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {campaignTypes} from "../../../../constants/smallConstants";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

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

      let campaignBalanceBefore = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy.address, campaignAddressPublic);
      let contractorBalanceBefore = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy.address, address);

      await protocol.CPCCampaign.contractorWithdraw(campaignAddressPublic, address);

      await new Promise(resolve => setTimeout(resolve, 5000));

      let contractorBalanceAfter = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy.address, address);

      const campaignBalanceAfter = await protocol.ERC20.getERC20Balance(protocol.twoKeyEconomy.address, campaignAddressPublic);

      expectEqualNumbers(contractorBalanceAfter, contractorBalanceBefore + campaignBalanceBefore);
      expect(campaignBalanceAfter).to.be.eq(0);
    }).timeout(60000)
  } else {
    it('should contractor withdraw his earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);

      const balanceBefore = (await protocol.getBalance(address)).balance;


      const contractorBalanceBefore = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
      );

      const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

      const balanceAfter = (await protocol.getBalance(address)).balance;

      if (userDeptsBefore > 0) {
        const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
        expect(userDeptsAfter).to.be.lt(userDeptsBefore);
      }

      expectEqualNumbers(
        Number.parseFloat(
          protocol.Utils.fromWei(
            Number.parseFloat(balanceAfter.ETH.toString())
            - Number.parseFloat(balanceBefore.ETH.toString()),
            'ether'
          ).toString()
        ),
        contractorBalanceBefore.available - userDeptsBefore
      );

      expect(contractorBalance.available).to.be.eq(0);
    }).timeout(60000);
  }
}
