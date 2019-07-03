require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
import { expect } from 'chai';

import TwoKeyIPFS from '../src/utils/ipfs';
import {ETwoKeyIPFSMode} from '../src/utils/interfaces';

const ipfsRegex = /Qm[a-zA-Z0-9]{44}/;

const ipfsGW = new TwoKeyIPFS('https://ipfs.2key.net', 443, {
    readPort: 443,
    readUrl: 'https://ipfs.2key.net/ipfs/',
    readMode: ETwoKeyIPFSMode.GATEWAY,
});

const ipfsAPI = new TwoKeyIPFS('https://ipfs.2key.net', 443, {
    readPort: 443,
    readUrl: 'https://ipfs.2key.net',
    readMode: ETwoKeyIPFSMode.API,
});

let hash;
const now = new Date().toLocaleTimeString();

describe('Test IPFS', () => {
    it('add object to ipfs', async () => {
        hash = await ipfsGW.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(600000);

    it('get object from ipfs', async () => {
        const obj = await ipfsGW.get(hash);
        expect(obj.now).to.be.equals(now);
    }).timeout(600000);

    it('get object from ipfs', async () => {
        const obj = await ipfsAPI.get(hash);
        expect(obj.now).to.be.equals(now);
    }).timeout(600000);
});
