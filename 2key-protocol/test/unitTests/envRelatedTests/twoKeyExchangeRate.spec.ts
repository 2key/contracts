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

let oraclesObjects = [];

let oracles = [
    usdSymbol,
    usdDaiSymbol,
    usd2KeySymbol,
    tusdSymbol,
    daiSymbol
];

let exchangeRates = {
    'USD': 100,
    'USD-DAI': 0.099,
    '2KEY-USD': 0.06,
    'TUSD-USD': 0.99,
    'DAI-USD': 0.97
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

    it('should check if oracle exists and if not, deploy one', async() => {


        for (const oracle of oracles) {
            let oracleAddress = await promisify(
                twoKeyProtocol.twoKeyExchangeContract.getChainLinkOracleAddress,[
                    oracle
                ]
            );

            if(oracleAddress.toString() == "0x0000000000000000000000000000000000000000") {
                let iContract = {
                    name: "MockChainLinkOracle",
                    abi: singletons.MockChainLinkOracle.abi,
                    bytecode: singletons.MockChainLinkOracle.bytecode,
                }
                // Here we should deploy new oracle contract
                let txHash = await twoKeyProtocol.createContract(iContract,from, {params: [18,oracle.toString(),1]});
                let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
                let txHash1 = await twoKeyProtocol.TwoKeyExchangeContract.setOracles(
                    [receipt.contractAddress],
                    [oracle],
                    from
                );
            }

            oraclesObjects.push({
                oracleName: oracle,
                oracleAddress: oracleAddress
            });
        }

        console.log(oraclesObjects)
    }).timeout(timeout);

    it('should set rates on oracles', async() => {
        for(const oracle of oraclesObjects) {
            let oracleInstance = twoKeyProtocol.web3.eth.contract(singletons.MockChainLinkOracle.abi).at(oracle.oracleAddress);
            const transformedBaseToTargetRate = parseFloat(twoKeyProtocol.Utils.toWei(exchangeRates[oracle.oracleName],'ether').toString());

            let txHash = await promisify(oracleInstance.updatePrice,[
                transformedBaseToTargetRate,
                {from}
            ]);
        }
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
