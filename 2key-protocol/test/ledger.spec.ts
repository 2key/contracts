import { ledgerWeb3 } from './_web3';
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');


describe('Test ledger', () => {
    it('should print accounts', async () => {
        const result = await ledgerWeb3('https://rpc.public.test.k8s.2key.net', 3);
        console.log('Accounts', result);
    }).timeout(600000);
});
