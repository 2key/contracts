import {BigNumber} from "bignumber.js";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import createWeb3 from './_web3';
import Sign from '../src/sign';
import {promisify} from "../src/utils/promisify";

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

let twoKeyProtocol: TwoKeyProtocol;
let from: string;
let config = require('../../configurationFiles/accountsConfig.json');

const sendETH: any = (recipient) => new Promise(async (resolve, reject) => {
    try {
        if (!twoKeyProtocol) {
            console.log('Creating TwoKeyProtocol instance');
            const {web3, address} = await createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
            from = address;
            twoKeyProtocol = new TwoKeyProtocol({
                web3,
                networks: {
                    mainNetId,
                    syncTwoKeyNetId,
                },
                plasmaPK: Sign.generatePrivateKey(),
            });
        }
        // console.log(twoKeyProtocol);
        const txHash = await twoKeyProtocol.transferEther(recipient, twoKeyProtocol.Utils.toWei(100, 'ether'), from);
        console.log(`${recipient}: ${txHash}`);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(`Status of transfering ether: ' + ${receipt.status}`);
        resolve(receipt);
    } catch (err) {
        reject(err);
    }
});


describe('TwoKeyProtocol LOCAL', () => {


    it('LOCAL: should transfer ether', async () => {
        let error = false;
        const addresses = Object.keys(env).filter(key => key.endsWith('_ADDRESS') && env[key].includes('0x') && env[key].length == 42).map(key => env[key]);
        addresses.push(config.address);
        let l = addresses.length;
        await sendETH('0x9aace881c7a80b596d38eaff66edbb5368d2f2c5');
        for (let i = 0; i < l; i++) {
            const receipt = await sendETH(addresses[i]);
            if (!receipt || receipt.status !== '0x1') {
                error = true;
            }
        }
        expect(error).to.be.false;
    }).timeout(600000);

    it('should print referrers per layer', async() => {
        let arcsForContractor = 1000;
        let arcsPerReferrer = 5;
        console.log('ARCS FOR CONTRACTOR: ' + arcsForContractor);
        console.log('ARCS PER REFERRER: ' + arcsPerReferrer);
        for(let i=0; i<10;i++) {
            console.log('Layer: ' + i.toString() + ' = ' + twoKeyProtocol.Utils.getMaxUsersPerLayer(i,arcsForContractor, arcsPerReferrer));
        }
    })
});
