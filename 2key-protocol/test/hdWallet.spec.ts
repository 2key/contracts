require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {expect} from 'chai';
import 'mocha';
import { generateWalletFromMnemonic } from './_web3';

describe('TwoKeyProtocol LOCAL', () => {
    it('LOCAL: should transfer ether', async () => {
        console.log(process.env.MNEMONIC);
        const { address, privateKey } = await generateWalletFromMnemonic(process.env.MNEMONIC);
        console.log(address, privateKey);
        expect(address).to.be.a('string');
    }).timeout(600000);
});
