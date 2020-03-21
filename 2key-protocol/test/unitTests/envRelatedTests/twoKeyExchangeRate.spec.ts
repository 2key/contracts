import {exchangeRates} from "../../constants/smallConstants";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {expect} from 'chai';
import 'mocha';
import web3Switcher from "../../helpers/web3Switcher";
import {TwoKeyProtocol} from "../../../src";
import getTwoKeyProtocol from "../../helpers/twoKeyProtocol";

const {env} = process;

const timeout = 60000;
const usdSymbol = 'USD';
const usdDaiSymbol = 'USD/DAI';

describe(
  'TwoKeyExchangeRateContract',
  () => {
    let from: string;
    let twoKeyProtocol: TwoKeyProtocol;

    before(
      function () {
        this.timeout(timeout);

        const {web3, address} = web3Switcher.deployer();

        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);
      }
    );

    it('should set dollar rate', async () => {
      const usdRate = 30;
      const txHash = await twoKeyProtocol.TwoKeyExchangeContract.setValue(
        usdSymbol,
        usdRate,
        from
      );
      await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
      const value = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdSymbol);

      expect(value).to.be.eq(usdRate);
    }).timeout(timeout);

    it('should set dollar/dai rate', async () => {
      const usdDaiRate = 50;

      const txHash = await twoKeyProtocol.TwoKeyExchangeContract.setValue(
        usdDaiSymbol,
        usdDaiRate,
        from);
      await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
      const value = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdDaiSymbol);

      expect(value).to.be.eq(usdDaiRate);
    }).timeout(timeout);

    it('should set dollar and dollar/dai rates with one request', async () => {
      const usdRate = exchangeRates.usd;
      const usdDaiRate = exchangeRates.usdDai;

      const txHash = await twoKeyProtocol.TwoKeyExchangeContract.setValues(
        [usdSymbol, usdDaiSymbol],
        [usdRate, usdDaiRate],
        from);
      await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
      let usdValue = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdSymbol);
      let usdDaiValue = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdDaiSymbol);

      expect(usdValue).to.be.eq(usdRate);
      expect(usdDaiValue).to.be.eq(usdDaiRate);
    }).timeout(timeout);

    it('should correctly exchange eth to dollar', async () => {
      const usdRate = exchangeRates.usd;
      const weiAmount = 100;

      const setRateTxHash = await twoKeyProtocol.TwoKeyExchangeContract.setValue(
        usdSymbol,
        usdRate,
        from
      );
      await twoKeyProtocol.Utils.getTransactionReceiptMined(setRateTxHash);
      const exchangedValue = await twoKeyProtocol.TwoKeyExchangeContract.exchangeCurrencies(
        usdSymbol,
        weiAmount,
      );

      expect(exchangedValue).to.be.eq(usdRate * weiAmount);
    }).timeout(timeout);
  }
);
