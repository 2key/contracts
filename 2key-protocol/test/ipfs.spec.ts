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

describe('IPFS: Basic scenario. Read from Gateway', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        const obj = await ipfs.get(hash);
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);

    it('add string to ipfs', async () => {
        hash = await ipfs.add(now);
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get string from ipfs through gateway', async () => {
        const result = await ipfs.get(hash, false);
        expect(result).to.be.equals(now);
    }).timeout(30000);
});

/*
describe('IPFS: Basic scenario. Wrong URLs', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.infura.io/api/v0', {
        readUrl: 'https://ipfs.infura.io/ipfs/',
        readMode: ETwoKeyIPFSMode.GATEWAY,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async() => {
        const worker = () => ipfs.add({ now });
        // @ts-ignore
        expect(await worker()).to.be.rejected;
    }).timeout(30000);

    it('get object from ipfs through gateway', async () => {
        expect(async() => {
            await ipfs.get(hash);
        }).to.throw(Error);

    }).timeout(30000);
});
 */

describe('IPFS: Basic scenario. Read from API', () => {
    const ipfs = new TwoKeyIPFS('https://ipfs.2key.net/api/v0', {
        readUrl: 'https://ipfs.2key.net/api/v0',
        readMode: ETwoKeyIPFSMode.API,
    });
    let hash;
    const now = new Date().toLocaleTimeString();

    it('add object to ipfs', async () => {
        hash = await ipfs.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash);
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
        hash = await ipfs.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash);
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
        hash = await ipfs.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash);
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
        hash = await ipfs.add({ now });
        expect(ipfsRegex.test(hash)).to.be.equals(true);
    }).timeout(30000);

    it('get object from ipfs through api', async () => {
        const obj = await ipfs.get(hash);
        expect(obj.now).to.be.equals(now);
    }).timeout(30000);
});
