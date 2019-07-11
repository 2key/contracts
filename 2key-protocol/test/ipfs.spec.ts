require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
import chai from 'chai';
import promisedChai from 'chai-as-promised';

import TwoKeyIPFS from '../src/utils/ipfs';
import {ETwoKeyIPFSMode} from '../src/utils/interfaces';

const expect = chai.expect;
chai.use(promisedChai);

const ipfsRegex = /Qm[a-zA-Z0-9]{44}/;
const campaign = require('./campaign.json');

describe('IPFS: Basic scenario. Read from Gateway', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(hash, { json: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);

    it('add string to ipfs', async () => {
        hash = await ipfs.add(now);
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get string from ipfs through gateway', async () => {
        const result = await ipfs.get(hash);
        expect(result).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Basic scenario. Read from API', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/api/v0',
        readMode: ETwoKeyIPFSMode.API,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash, { json: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Read from GW, multiple API endpoints', () => {
    const ipfs = new TwoKeyIPFS(['https://infura.ipfs.io/api/v2', 'https://18.233.2.70:9095/api/v0', 'https://ipfs.2key.net/api/v0'], {
        readUrl: 'https://ipfs.2key.net/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash, { json: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Read from wrong GW', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash, { json: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Read from wrong GW, multiple API endpoints', () => {
    const ipfs = new TwoKeyIPFS(['https://infura.ipfs.io/api/v2', 'https://18.233.2.70:9095/api/v0', 'https://ipfs.2key.net/api/v0'], {
        readUrl: 'https://ipfs.2key.net/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash, { json: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Basic scenario with compression. Read from GW', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true, compress: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(hash, { json: true, compress: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Basic scenario with compression. Read from API', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/api/v0',
        readMode: ETwoKeyIPFSMode.API,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now }, { json: true, compress: true });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(hash, { json: true, compress: true });
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});

describe('IPFS: Compare sizes', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let compressedHash;
    let rawHash;

    it('add object to ipfs', async () => {
        rawHash = await ipfs.add(campaign, { json: true });
        expect(ipfsRegex.test(rawHash)).to.be.equals(true);
    }).timeout(30000);

    it('add object to ipfs', async () => {
        compressedHash = await ipfs.add(campaign, { json: true, compress: true });
        expect(ipfsRegex.test(compressedHash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(rawHash, { json: true });
        expect(obj.erc20_address).to.be.equals('0xaf65314b914a116bc299d97ab01b2fe870046f7a');
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(compressedHash, { json: true, compress: true });
        expect(obj.erc20_address).to.be.equals('0xaf65314b914a116bc299d97ab01b2fe870046f7a');
    }).timeout(30000);
});

