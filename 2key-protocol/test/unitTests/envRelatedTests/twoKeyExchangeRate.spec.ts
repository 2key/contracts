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

const timeout = 10000;
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
        let managerInstance = new twoKeyProtocol.web3.eth.Contract(singletons.MockOraclesManager.abi, managerAddress);

        let deployedOracle = await promisify(managerInstance.methods.pairToOracleAddress,[descriptions[0]]);
        if(deployedOracle.toString().toLowerCase() == '0x0000000000000000000000000000000000000000') {
            await twoKeyProtocol.Utils.getTransactionReceiptMined(
                await promisify(managerInstance.methods.deployAndStoreOracles,[
                    18,
                    descriptions,
                    1,
                    {from: from}
                ])
            );



            let resp = await promisify(managerInstance.methods.getDeployedOraclesAndDescriptions,[]);

            let oracleAddresses = resp['0'];
            let deployedDescriptions = resp['1'];


            let counter = 0;

            for (const description of deployedDescriptions) {
                let oracleAddressFromContract = await promisify(managerInstance.methods.pairToOracleAddress,[description]);
                expect(oracleAddressFromContract.toString().toLowerCase())
                    .to.be.equal(oracleAddresses[counter].toString().toLowerCase());

                counter++;
            }

            await twoKeyProtocol.Utils.getTransactionReceiptMined(
                await promisify(twoKeyProtocol.twoKeyExchangeContract.methods.storeChainLinkOracleAddresses,[
                    descriptions,
                    oracleAddresses,
                    {
                        from: from
                    }
                ])
            );
        }
    }).timeout(timeout);

    it('should set rates on oracles', async() => {
        let rates = [];
        let oracleNamesHex = [];

        let managerAddress = await twoKeyProtocol.SingletonRegistry.getNonUpgradableContractAddress('MockOraclesManager');

        // Create manager instance
        let managerInstance = new twoKeyProtocol.web3.eth.Contract(singletons.MockOraclesManager.abi, managerAddress);

        for (const [key, value] of Object.entries(exchangeRates)) {
            let val = twoKeyProtocol.Utils.toWei(value).toString();
            rates.push(val);
        }

        for(const oracle of oracles) {
            oracleNamesHex.push(twoKeyProtocol.Utils.toHex(oracle));
        }

        await twoKeyProtocol.Utils.getTransactionReceiptMined(
            await promisify(managerInstance.methods.updateRates,[
                oracleNamesHex,
                rates,
                {
                    from
                }
            ])
        );
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

      const exchangedValue = await twoKeyProtocol.TwoKeyExchangeContract.exchangeCurrencies(
        usdSymbol,
        weiAmount,
      );

      expect(exchangedValue).to.be.eq(usdRate * weiAmount);
    }).timeout(timeout);

    it('should get fiat to stable coin quotes', async () => {
        let amountFiatWei = twoKeyProtocol.Utils.toWei(15,'ether').toString();
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
