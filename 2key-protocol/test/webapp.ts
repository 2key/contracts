import crypto from 'crypto';
import {TwoKeyProtocol} from '../src';

document.addEventListener('DOMContentLoaded', () => {
    const btn = document.getElementById('init2key');
    const plasmaInput = document.getElementById('plasma');
    const mainNet = document.getElementById('mainNet');
    const plasmaNet = document.getElementById('plasmaNet');
    btn.addEventListener('click', (e) => {
        // @ts-ignore
        const { web3 } = window;
        if (web3 && web3.currentProvider && web3.eth.defaultAccount) {
            const plasmaPK = crypto.randomBytes(32).toString('hex');
            const address = web3.eth.defaultAccount;
            // web3.eth.defaultBlock = 'pending';
            // @ts-ignore
            window.TWOKEY = new TwoKeyProtocol({
                web3,
                address,
                networks: {
                    // @ts-ignore
                    mainNetId: mainNet.value,
                    // @ts-ignore
                    syncTwoKeyNetId: plasmaNet.value,
                },
                // @ts-ignore
                eventsNetUrl: plasmaInput.value,
                plasmaPK,
                log: console.log,
            });
            alert('Now you can user TWOKEY');
        } else {
            alert('Metamask plugin not found')
        }
    });
});
