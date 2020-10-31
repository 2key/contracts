import {expect} from 'chai';
import 'mocha';
import {promisify} from "../../../src/utils/promisify";
import web3Switcher from "../../helpers/web3Switcher";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

const {env} = process;

const rpcUrls = [env.RPC_URL];

let web3: any;
let from: string;
let config = require('../../../../configurationFiles/accountsConfig.json');

const getReceipt = (txHash: string, { web3, timeout = 60000, interval = 500}) => new Promise(async (resolve, reject) => {
    let txInterval;
    let fallbackTimeout = setTimeout(() => {
        if (txInterval) {
            clearInterval(txInterval);
            txInterval = null;
        }
        reject('Operation timeout');
    }, timeout);
    txInterval = setInterval(async () => {
        try {
            const receipt = await promisify(web3.eth.getTransactionReceipt, [txHash]);
            if (receipt) {
                if (fallbackTimeout) {
                    clearTimeout(fallbackTimeout);
                    fallbackTimeout = null;
                }
                if (txInterval) {
                    clearInterval(txInterval);
                    txInterval = null;
                }
                resolve(receipt);
            }
        } catch (e) {
            if (fallbackTimeout) {
                clearTimeout(fallbackTimeout);
                fallbackTimeout = null;
            }
            if (txInterval) {
                clearInterval(txInterval);
                txInterval = null;
            }
            reject(e);
        }
    }, interval);
});

const sendETH: any = (recipient) => new Promise(async (resolve, reject) => {
    try {
        if (!web3) {
            const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.deployer();

            from = address;
        }

        const txHash = await promisify(web3.eth.sendTransaction, [{ to: recipient, value: web3.toWei(100, 'ether'), from }]);

        const receipt = await getReceipt(txHash, { web3 });
        resolve(receipt);
    } catch (err) {
        reject(err);
    }
});


describe('TwoKeyProtocol LOCAL', () => {


    it('LOCAL: should transfer ether without errors', async () => {
        let error = false;
        const addresses = Object.keys(env).filter(key => key.endsWith('_ADDRESS') && env[key].includes('0x') && env[key].length == 42).map(key => env[key]);
        addresses.push(config.address);
        let l = addresses.length;
        await sendETH('0x9aace881c7a80b596d38eaff66edbb5368d2f2c5'); //To make sure for tests
        await sendETH('0xfE597d4BFa6D16b3a42510b0b9A5d69E45a2F0E2'); //Ledger address
        await sendETH('0x11e9Ce4382fF83BD1222D1EB519D5663C2DC1374'); //Ledger address
        for (let i = 0; i < l; i++) {
            const receipt = await sendETH(addresses[i]);
            if (!receipt || receipt.status !== '0x1') {
                error = true;
            }
        }
        expect(error).to.be.false;
    }).timeout(600000);

    // it('should print referrers per layer', async() => {
    //     let arcsForContractor = 1000;
    //     let arcsPerReferrer = 5;
    //     console.log('ARCS FOR CONTRACTOR: ' + arcsForContractor);
    //     console.log('ARCS PER REFERRER: ' + arcsPerReferrer);
    //     for(let i=0; i<10;i++) {
    //         console.log('Layer: ' + i.toString() + ' = ' + twoKeyProtocol.Utils.getMaxUsersPerLayer(i,arcsForContractor, arcsPerReferrer));
    //     }
    // })
});
