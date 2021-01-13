import {expect} from 'chai';
import 'mocha';
import web3Switcher from "../../helpers/web3Switcher";
import {TwoKeyProtocol} from "../../../src";
import getTwoKeyProtocol from "../../helpers/twoKeyProtocol";
import {promisify} from "../../../src/utils/promisify";
import singletons from "../../../src/contracts/singletons";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

const {env} = process;

const timeout = 60000;
const usdSymbol = 'USD';
const usdDaiSymbol = 'USD-DAI';
const usd2KeySymbol = '2KEY-USD';
const tusdSymbol = 'TUSD-USD';
const daiSymbol = 'DAI-USD';
const daiEthSymbol = 'DAI-ETH'
const tusdEthSymbol = 'TUSD-ETH'

let oraclesObjects = [];

let oracles = [
    usdSymbol,
    usdDaiSymbol,
    usd2KeySymbol,
    tusdSymbol,
    daiSymbol,
    daiEthSymbol,
    tusdEthSymbol
];

let exchangeRates = {
    'USD': 100,
    'USD-DAI': 1.03,
    '2KEY-USD': 0.06,
    'TUSD-USD': 0.99,
    'DAI-USD': 0.97,
    'DAI-ETH': 0.0097,
    'TUSD-ETH': 0.0099
}


describe(
  'TwoKeyExchangeRateContract',
  () => {
    let from: string;
    let twoKeyProtocol: TwoKeyProtocol;

    before(
      function () {
          this.timeout(timeout);

          const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.deployer();

          from = address;
          twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);
      }
    );

    it('should deploy oracles using manager contract', async() => {

        let managerAddress = await twoKeyProtocol.SingletonRegistry.getNonUpgradableContractAddress('MockOraclesManager');
        let descriptions = [];

        for(const oracle of oracles) {
            descriptions.push(twoKeyProtocol.Utils.toHex(oracle));
        }

        // Create manager instance
        let managerInstance = twoKeyProtocol.web3.eth.contract(singletons.MockOraclesManager.abi).at(managerAddress);

        let txHash = await promisify(managerInstance.deployAndStoreOracles,[
            18,
            descriptions,
            1,
            {from: from}
        ]);

        // At this certain point we can assume that all oracles are freshly deployed
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        let [oracleAddresses,deployedDescriptions] = await promisify(managerInstance.getDeployedOraclesAndDescriptions,[]);

        console.log(oracleAddresses, deployedDescriptions);
        let counter = 0;

        for (const description of deployedDescriptions) {
            let oracleAddressFromContract = await promisify(managerInstance.pairToOracleAddress,[description]);
            expect(oracleAddressFromContract.toString().toLowerCase())
                .to.be.equal(oracleAddresses[counter].toString().toLowerCase());

            counter++;
        }

        // Now it's time to store this oracles inside TwoKeyExchangeRateContract
        let txHash1 = await promisify(twoKeyProtocol.twoKeyExchangeContract.storeChainLinkOracleAddresses,[
            descriptions,
            oracleAddresses,
            {from: from}
        ]);

    }).timeout(timeout);


    it('should set rates on oracles', async() => {
        let rates = [];
        let oracleNamesHex = [];

        let managerAddress = await twoKeyProtocol.SingletonRegistry.getNonUpgradableContractAddress('MockOraclesManager');

        // Create manager instance
        let managerInstance = twoKeyProtocol.web3.eth.contract(singletons.MockOraclesManager.abi).at(managerAddress);

        for (const [key, value] of Object.entries(exchangeRates)) {
            rates.push(twoKeyProtocol.Utils.toWei(value));
        }

        for(const oracle of oracles) {
            oracleNamesHex.push(twoKeyProtocol.Utils.toHex(oracle));
        }


        let txHash = await promisify(managerInstance.updateRates,[
            oracleNamesHex,
            rates,
            {
                from
            }
        ]);

        let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(timeout);


    it('should check dollar dai, dollar 2Key rates', async () => {
      const usdRate = exchangeRates.USD;
      const usdDaiRate = exchangeRates["USD-DAI"];
      const usd2KeyRate = exchangeRates["2KEY-USD"];
      const daiUsdRate = exchangeRates["DAI-USD"];
      const tusdUsdRate = exchangeRates["TUSD-USD"];

      let usdValue = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdSymbol);
      let usdDaiValue = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usdDaiSymbol);
      let usd2KeyValue = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate(usd2KeySymbol);
      expect(usdValue).to.be.eq(usdRate);
      expect(usdDaiValue).to.be.eq(usdDaiRate);
      expect(usd2KeyValue).to.be.eq(usd2KeyRate);
    }).timeout(timeout);

    it('should correctly exchange eth to dollar', async () => {
      const usdRate = exchangeRates.USD;
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

    it('should get fiat to stable coin quotes', async () => {
        let amountFiatWei = parseFloat(twoKeyProtocol.Utils.toWei(15,'ether').toString());
        let pairs = await twoKeyProtocol.TwoKeyExchangeContract.getFiatToStableQuotes(amountFiatWei, 'USD', ['DAI','TUSD']);
        console.log(pairs);
    }).timeout(timeout);

    it('should get stable coin quota by address', async () => {
      let daiAddress = await twoKeyProtocol.SingletonRegistry.getNonUpgradableContractAddress('DAI');
      let quota = await twoKeyProtocol.TwoKeyExchangeContract.getStableCoinToUSDQuota(
        daiAddress
      );
      expect(quota).to.be.equal(exchangeRates["DAI-USD"]);
    })
  }
);
