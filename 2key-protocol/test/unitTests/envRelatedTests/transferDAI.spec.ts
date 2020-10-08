require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {expect} from 'chai';
import 'mocha';
import web3Switcher from "../../helpers/web3Switcher";
import {TwoKeyProtocol} from "../../../src";
import getTwoKeyProtocol from "../../helpers/twoKeyProtocol";

const {env} = process;

const timeout = 60000;

describe(
    'Transfer DAI tokens to users',
    () => {
        let from: string;
        let twoKeyProtocol: TwoKeyProtocol;

        before(
            function () {
                this.timeout(timeout);

                const {web3, address} = web3Switcher.deployer();

                from = address;
                twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);
            }
        );

        it('should transfer DAI to all addresses', async () => {
            // Fetch almost all addresses involved in test process.
            const addresses =
                Object.keys(env).filter(key => key.endsWith('_ADDRESS') &&
                    env[key].includes('0x') &&
                    env[key].length == 42).map(key => env[key]);

            let len = addresses.length;
            let value = 1000;
            let daiAddress = await twoKeyProtocol.SingletonRegistry.getNonUpgradableContractAddress("DAI");
            for (let i = 0; i < len; i++) {
                if(addresses[i] != from) {
                    // Take balance before transfer
                    let balanceBefore = await twoKeyProtocol.ERC20.getERC20Balance(daiAddress, addresses[i]);
                    // Transfer tokens and wait until tx gets mined.
                    await twoKeyProtocol.Utils.getTransactionReceiptMined(
                        await twoKeyProtocol.ERC20.transfer(
                            daiAddress, //dai address
                            addresses[i],
                            twoKeyProtocol.Utils.toWei(value, 'ether').toString(),
                            from
                        )
                    );

                    // Take balance after transfer
                    let balanceAfter = await twoKeyProtocol.ERC20.getERC20Balance(daiAddress, addresses[i]);
                    expect(balanceAfter).to.be.equal(balanceBefore+value);
                } 
            }
        }).timeout(timeout);
    }
);
