import '../constants/polifils';
import {describe, it} from 'mocha';
import {expect} from "chai";
import availableUsers from "../constants/availableUsers";
import web3Switcher from "../helpers/web3Switcher";
import {getTwoKeyProtocolValues} from "../helpers/twoKeyProtocol";

const {web3: {address: from}, protocol: deployerProtocol} = availableUsers.deployer;
const {address: aydnepAddress, protocol: aydnepProtocol} = availableUsers.aydnep;


describe('TwoKeyProtocol root methods test', () => {
  it(`should return estimated gas for transfer ether ${aydnepAddress}`, async () => {
    const gas = await deployerProtocol.getETHTransferGas(aydnepAddress, deployerProtocol.Utils.toWei(10, 'ether'), from);
    console.log('Gas required for ETH transfer', gas);
    expect(gas).to.exist.to.be.greaterThan(0);
  }).timeout(60000);

  it('should return a balance', async () => {
    const balance = aydnepProtocol.Utils.balanceFromWeiString(
      await aydnepProtocol.getBalance(aydnepAddress),
      {inWei: true},
      );

    return expect(balance).to.exist
      .to.haveOwnProperty('gasPrice')
    // .to.be.equal(twoKeyProtocol.getGasPrice());
  }).timeout(60000);

  // TODO: Not working: initial and result balances have incorrect diff
  it(`should transfer ether to ${aydnepAddress}`, async () => {
    // const initialBalance = aydnepProtocol.Utils.balanceFromWeiString(
    //   await deployerProtocol.getBalance(aydnepAddress),
    //   {
    //     inWei: true,
    //     toNum: true
    //   },
    // );
    const transferAmount = deployerProtocol.Utils.toWei(1, 'ether');
    const txHash = await deployerProtocol.transferEther(
      aydnepAddress, transferAmount, from, 6000000000,
    );
    const receipt = await deployerProtocol.Utils.getTransactionReceiptMined(txHash);
    const resultBalance = aydnepProtocol.Utils.balanceFromWeiString(
      await deployerProtocol.getBalance(aydnepAddress),
      {
        inWei: true,
        toNum: true
      },
    );

    const status = receipt && receipt.status;
    expect(status).to.be.equal('0x1');
  }).timeout(60000);
});
