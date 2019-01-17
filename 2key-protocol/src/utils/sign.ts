import eth_util, {toBuffer} from 'ethereumjs-util';
import eth_wallet from 'ethereumjs-wallet';
import *  as cryptoJS from 'crypto-js'
import assert from 'assert';
import sigUtil from 'eth-sig-util';
import {IPlasmaSignature, ISignedKeys} from './interfaces';


/**
 * Helper function to add 0x at the beginning of the address
 * @param x
 * @returns {any}
 */
function add0x(x) {
    if (!x) {
        return '0x';
    }
    if (x.startsWith('0x')) {
        return x;
    } else {
        return '0x' + x;
    }
}

/**
 * Removes 0x from the beginning
 * @param x string
 * @returns {any}
 */
function remove0x(x) {
    if (!x) {
        return;
    }
    if (x.startsWith('0x')) {
        if (x.length == 2) {
            return;
        }
        return x.slice(2);
    } else {
        return x;
    }
}

/**
 * GetKey subFunction
 * @param web3
 * @param me
 * @returns {Promise<Buffer>}
 */
async function getKey(web3, me, opts: IOptionalParamsSignMessage) {
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'Password used to generate key',     // Any string label you want
            value: me  // The value to sign
        }
    ];

    let key = await sign_message(web3, msgParams, me, opts);
    key = remove0x(key);
    key = key.slice(0, 24 * 2);
    return Buffer.from(key, 'hex');
}

/**
 *
 * @param plasma_web3
 * @param my_address
 * @param plasma_address
 * @returns {Promise<string>}
 */
function sign_ethereum2plasma(plasma_web3, my_address, plasma_address): Promise<string> {
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to ethereum address',     // Any string label you want
            value: my_address  // The value to sign
        }
    ];

    return sign_message(plasma_web3, msgParams, plasma_address, {plasma: true}); // we never use metamask on plasma
}

/**
 *
 * @param plasma_address
 * @param my_address
 * @returns {Promise<string>}
 */
function sign_plasma2ethereum(web3, plasma_address, my_address): Promise<string> {
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to plasma address',     // Any string label you want
            value: plasma_address  // The value to sign
        }
    ];
    return sign_message(web3, msgParams, my_address, {plasma: true});
}

/**
 *
 * @param web3
 * @param my_address
 * @param ethereum2plasma_sig
 * @param note
 * @returns {Promise<string>}
 */
function sign_ethereum2plasma_note(web3, my_address, ethereum2plasma_sig, note): Promise<string> {
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to ethereum-plasma',     // Any string label you want
            value: ethereum2plasma_sig + remove0x(note)  // The value to sign
        }
    ];
    return sign_message(web3, msgParams, my_address, {plasma: false}) // we never use metamask on plasma
}

/**
 *
 * @param web3
 * @param me
 * @param encrypted
 * @returns {Promise<any>}
 */
function decrypt(web3, me, encrypted, opts: IOptionalParamsSignMessage): Promise<string> {
    return new Promise(async (resolve, reject) => {
        encrypted = remove0x(encrypted);
        if (!encrypted) {
            resolve();
            return;
        }
        let keyBuffer = await getKey(web3, me, opts);
        let iv0 = encrypted.slice(0, 32);
        let iv = cryptoJS.enc.Hex.parse(iv0);
        encrypted = encrypted.slice(32);

        let key = keyBuffer.toString('hex');
        var reb64 = cryptoJS.enc.Hex.parse(encrypted);
        var bytes = reb64.toString(cryptoJS.enc.Base64);
        var decrypt = cryptoJS.AES.decrypt(bytes, key, {iv});
        var plain = decrypt.toString(cryptoJS.enc.Utf8);
        plain = add0x(plain);
        resolve(plain);
    })
}

/**
 *
 * @param web3
 * @param address
 * @param clear_text
 * @returns {Promise<any>}
 */
function encrypt(web3, address, clear_text, opts: IOptionalParamsSignMessage): Promise<string> {
    return new Promise(async (resolve, reject) => {
        if (!clear_text) {
            resolve('0x');
            return;
        }
        clear_text = remove0x(clear_text);
        let iv0 = cryptoJS.lib.WordArray.random(16);
        let keyBuffer = await getKey(web3, address, opts);
        iv0 = iv0.toString(cryptoJS.enc.Hex);
        let iv = cryptoJS.enc.Hex.parse(iv0);
        clear_text = clear_text.toString('hex');
        let key = keyBuffer.toString('hex');
        let b64 = cryptoJS.AES.encrypt(clear_text, key, {iv}).toString();
        let e64 = cryptoJS.enc.Base64.parse(b64);
        let eHex = e64.toString(cryptoJS.enc.Hex);
        let encrypted = iv0 + eHex;
        encrypted = add0x(encrypted);
        resolve(encrypted);
    })
}

function generatePrivateKey(): string {
    return cryptoJS.lib.WordArray.random(32).toString(cryptoJS.enc.Hex)

}

function privateToPublic(private_key: Buffer) {
    // convert a private_key buffer to a public address string
    // @ts-ignore: Missing declaration of publicToAddress in ethereumjs-util
    return eth_util.publicToAddress(eth_util.privateToPublic(private_key)).toString('hex');
}

function free_take(my_address: string, f_address: string, f_secret?: string, p_message?: string) {
    // using information in the signed link (f_address,f_secret,p_message)
    // return a new message that can be passed to the transferSig method of the contract
    // to move ARCs arround in the current. For example:
    //   campaign_contract.transferSig(free_take (my_address,f_address,f_secret,p_message))
    //
    // my_address - I'm a new influencer or a converter
    // f_address - previous influencer
    // f_secret - the secret of the parent (contractor or previous influencer) is passed in the 2key link
    // p_message - the message built by previous influencers
    const old_private_key = Buffer.from(f_secret, 'hex');
    if (!eth_util.isValidPrivate(old_private_key)) {
        throw new Error('old private key not valid');
    }

    let m;
    const version = p_message ? p_message.slice(0, 2) : '00';
    // let prefix = "00"  // not reall important because it only used when receiving a free link directly from the contractor

    if (p_message) {  // the message built by previous influencers
        m = p_message;
        if (version === '00') {
            m += f_address.slice(2);
        }
        const old_public_address = privateToPublic(old_private_key);
        m += old_public_address
    } else {
        // this happens when receiving a free link directly from the contractor
        m = `00${f_address.slice(2)}`;
    }


    // the message we want to sign is my address (I'm the converter)
    // and we will sign with the private key from the previous step (contractor or influencer)
    // this will prove that I (my address) knew what the previous private key was
    const msg = Buffer.from(my_address.slice(2), 'hex'); // skip 0x
    const msgHash = eth_util.sha3(msg);
    let sig = eth_util.ecsign(msgHash, old_private_key);
    assert.ok(sig.v === 27 || sig.v === 28, 'unknown sig.v');

    sig = Buffer.concat([sig.r, sig.s, Buffer.from([sig.v])]);

    // TODO: Fix this
    // @ts-ignore: custom toString() implementation
    m += sig.toString('hex');
    m = `0x${m}`;
    return m;
}

function free_join(my_address: string, public_address: string, f_address: string, f_secret: string, p_message: string, rCut: number, cutSign?: string): string {
    // let cut = fcut;
    // Input:
    //   my_address - I'm an influencer that wants to generate my own link
    //   public_address - the public address of my private key
    // return - my new message

    // the message we want to sign is my address (I'm the influencer or converter)
    // and the public key of the private key which I will put in the link
    // and we will sign all of this with the private key from the previous step,
    // this will prove that I (my address) knew what the previous private key was
    // and it will link the new private/public key to the previous keys to form a path
    const msg0 = Buffer.from(public_address, 'hex');
    const msg1 = Buffer.from(my_address.slice(2), 'hex'); // skip 0x
    let msg = Buffer.concat([msg0, msg1]); // compact msg (as is done in sha3 inside solidity)
    // if not using version prefix to the message:
    let cut: any = rCut;
    if (cut == null) {
        cut = 255; // equal partition
    }
    cut = Buffer.from([cut]);
    msg = Buffer.concat([cut, msg]); // compact msg (as is done in sha3 inside solidity)
    const msgHash = eth_util.sha3(msg);
    const old_private_key = Buffer.from(f_secret, 'hex');
    let sig = eth_util.ecsign(msgHash, old_private_key);

    // check the signature
    // this is what the contract will do
    let recovered_address = eth_util.ecrecover(msgHash, sig.v, sig.r, sig.s);
    // @ts-ignore: Missing declaration of publicToAddress in ethereumjs-util
    recovered_address = eth_util.publicToAddress(recovered_address).toString('hex');
    const old_public_address = privateToPublic(old_private_key);
    assert.equal(recovered_address, old_public_address, 'sig failed');

    sig = Buffer.concat([sig.r, sig.s, Buffer.from([sig.v])]);
    let m: Buffer | string = Buffer.concat([sig, cut]);
    m = m.toString('hex');

    const version = cutSign ? '01' : '00';
    let previousMessage = p_message;
    if (previousMessage) {
        if (version === '00') {
            previousMessage += f_address.slice(2)
        }
        previousMessage += old_public_address;
        // m = previousMessage + f_address.slice(2) + old_public_address + m;
    } else {
        previousMessage = version + f_address.slice(2);
        // this happens when receiving a free link directly from the contractor
        // m = f_address.slice(2) + m;
    }
    assert.ok(previousMessage.startsWith(version));
    m = previousMessage + m;
    if (cutSign) {
        console.log('CUT SIGN', cutSign);
        if (cutSign.startsWith('0x')) {
            m += cutSign.slice(2)
        } else {
            m += cutSign
        }
    }
    return m;
}

function free_join_take(my_address: string, public_address: string, f_address: string, f_secret: string, p_message: string, cut?: number): string {
    // using information in the signed link (f_address,f_secret,p_message)
    // return a new message that can be passed to the transferSig method of the contract
    // to move ARCs arround in the current. For example:
    //   campaign_contract.transferSig(free_take (my_address,f_address,f_secret,p_message))
    // unlike free_take, this function will give information to transferSig so in the future, if I want,
    // I can also become an influencer
    //
    // my_address - I'm a new influencer or a converter
    // public_address - the public key of my secret that I will put in a link that I will generate
    // f_address - previous influencer
    // f_secret - the secret of the parent (contractor or previous influencer) is passed in the 2key link
    // p_message - the message built by previous influencers
    // cut - this should be a number between 0 and 255.
    //   value from 1 to 101 are translated to percentage in the contract by removing 1.
    //   all other values are used to say use default behaviour
    let m = free_join(my_address, public_address, f_address, f_secret, p_message, cut);
    m += my_address.slice(2) + public_address;
    return `0x${m}`;
}

function recoverHash(hash1, p_message) {
    // same as recoverHash in Call.sol
    // read signature
    let r1 = p_message.slice(0, 32 * 2);
    r1 = Buffer.from(r1, 'hex');
    p_message = p_message.slice(32 * 2);
    let s1 = p_message.slice(0, 32 * 2);
    s1 = Buffer.from(s1, 'hex')
    p_message = p_message.slice(32 * 2);
    let v1 = p_message.slice(0, 1 * 2);
    v1 = Buffer.from(v1, 'hex')[0];
    p_message = p_message.slice(1 * 2);

    if (v1 >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
        let p = Buffer.from('\u0019Ethereum Signed Message:\n32');  // 32 is the number of bytes in the following hash1
        hash1 = Buffer.concat([p, hash1]);
        hash1 = eth_util.sha3(hash1);
        v1 -= 32
    }
    if (v1 <= 1) {
        v1 += 27
    }
    assert.ok(v1 == 27 || v1 == 28, 'unknown sig.v');
    let new_address = eth_util.ecrecover(hash1, v1, r1, s1);
    // @ts-ignore
    new_address = eth_util.publicToAddress(new_address).toString('hex');
    console.log(new_address);
    return new_address;
}

function validate_join(firtsPublicKey: string, f_address: string, f_secret: string, pMessage: string): number[] {
    console.log('Validate join', firtsPublicKey, f_address, f_secret, pMessage);
    const bounty_cuts = [];

    let last_private_key;
    let last_public_key;
    let first_public_key: any = firtsPublicKey;
    let p_message = pMessage;
    if (f_secret) {
        last_private_key = Buffer.from(f_secret, 'hex');
        assert.ok(eth_util.isValidPrivate(last_private_key), 'last private key not valid');
        last_public_key = privateToPublic(last_private_key);
    }

    if (first_public_key.startsWith('0x')) {
        first_public_key = first_public_key.slice(2);
    }
    if (!p_message) {
        assert.ok(first_public_key == last_public_key, 'keys dont match');
        return bounty_cuts
    }

    if (p_message.startsWith('0x')) {
        p_message = p_message.slice(2);
    }

    let version = p_message.slice(0, 2);
    p_message = p_message.slice(2);
    assert.ok(version === '00' || version === '01');
    if (f_address) {
        if (version === '00') {
            p_message += f_address.slice(2);
        }
        if (last_public_key) {
            p_message += last_public_key;
        }
    }

    assert.ok(p_message.length >= 2 * 20, 'message length too short');
    let old_address = p_message.slice(0, 2 * 20);
    p_message = p_message.slice(2 * 20);
    let msg_len = (version === '01') ? 86 : 41;

    while (p_message.length >= 2 * (65 + msg_len)) {
        // not having the last 41 bytes can happen only for last step of a converter
        // read signature
        let r: any = p_message.slice(0, 32 * 2);
        r = Buffer.from(r, 'hex');
        p_message = p_message.slice(32 * 2);
        let s: any = p_message.slice(0, 32 * 2);
        s = Buffer.from(s, 'hex');
        p_message = p_message.slice(32 * 2);
        let v: any = p_message.slice(0, 1 * 2);
        v = Buffer.from(v, 'hex')[0];
        assert.ok(v == 27 || v == 28, 'unknown sig.v');
        p_message = p_message.slice(1 * 2);

        let bounty_cut: any = p_message.slice(0, 1 * 2);
        p_message = p_message.slice(1 * 2);
        bounty_cut = Buffer.from(bounty_cut, 'hex');
        assert.ok(bounty_cut[0] !== 0, 'cut=0, use 255 for equal parts');
        bounty_cuts.push(bounty_cut[0]);

        let new_address;
        if (msg_len == 41) {
            new_address = p_message.slice(0, 20 * 2);
            p_message = p_message.slice(20 * 2);
            new_address = Buffer.from(new_address, 'hex');
        } else {
            let hash1 = eth_util.sha3(Buffer.concat([eth_util.sha3(Buffer.from("bytes binding to weight")), eth_util.sha3(bounty_cut)]));
            new_address = recoverHash(hash1, p_message);
            p_message = p_message.slice(65 * 2);
            new_address = Buffer.from(new_address, 'hex');
        }

        let new_public_key: any = p_message.slice(0, 20 * 2);
        p_message = p_message.slice(20 * 2);
        new_public_key = Buffer.from(new_public_key, 'hex');

        let hash: any = Buffer.concat([bounty_cut, new_public_key, new_address]);
        hash = eth_util.sha3(hash);

        let recovered_address = eth_util.ecrecover(hash, v, r, s);
        // @ts-ignore
        recovered_address = eth_util.publicToAddress(recovered_address).toString('hex');
        assert.ok(first_public_key == recovered_address, 'signature failed');

        old_address = new_address;
        first_public_key = new_public_key.toString('hex');
    }

    assert.ok(p_message.length === 0, 'bad message length');

    return bounty_cuts;
}

//TODO: Remove this function if we don't use and need it anywhere ASAP change in acquisition
function sign_plasma2eteherum(plasma_address: string, my_address: string, web3: any): Promise<string> {
    const msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to plasma address',     // Any string label you want
            value: plasma_address  // The value to sign
        }
    ];

    return new Promise((resolve, reject) => {
        if (!web3 || !web3.currentProvider) {
            reject('No web3 instance');
        }
        const {isMetaMask = false} = web3.currentProvider;
        console.log('METAMASK', isMetaMask);

        function cb(err, result) {
            if (err) {
                console.log('Error in sign_plasma2eteherum ' + err);
                reject(err)
            } else if (!result) {
                console.log('Error in sign_plasma2eteherum no result');
                reject();
            } else {
                let sig = typeof result != 'string' ? result.result : result;

                if (!isMetaMask) {
                    let n = sig.length;
                    let v = sig.slice(n - 2);
                    v = parseInt(v, 16) + 32;
                    v = Buffer.from([v]).toString('hex');
                    sig = sig.slice(0, n - 2) + v;
                }

                resolve(sig)
            }
        }

        if (isMetaMask) {
            // metamask uses  web3.eth.sign to sign transaction and not for arbitrary messages
            // instead use https://medium.com/metamask/scaling-web3-with-signtypeddata-91d6efc8b290
            web3.currentProvider.sendAsync({
                method: 'eth_signTypedData',
                params: [msgParams, my_address],
                from: my_address,
            }, cb)
        } else {
            let msg = sigUtil.typedSignatureHash(msgParams);
            // console.log(msg);
            if (web3.eth.getSign) {
                web3.eth.getSign(my_address, msg, cb)
            } else {
                // TODO Crazy bug in Web3 in doc it is said that msg should come first https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
                web3.eth.sign(my_address, msg, cb)
            }
        }
    })
}

function sign_cut2eteherum(userCut: number, my_address: string, web3: any): Promise<string> {
    const cut = '0x' + Buffer.from([userCut]).toString('hex');
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to weight',     // Any string label you want
            value: cut  // The value to sign
        }
    ];

    return new Promise((resolve, reject) => {
        if (!web3 || !web3.currentProvider) {
            reject('No web3 instance');
        }
        const {isMetaMask} = web3.currentProvider;

        function cb(err, result) {
            if (err) {
                console.log('Error in sign_cut2eteherum', err);
                reject(err)
            } else if (!result) {
                console.log('Error in sign_cut2eteherum no result');
                reject();
            } else {
                if (typeof result != 'string') {
                    result = result.result
                }


                if (!isMetaMask) {
                    let n = result.length;
                    let v = result.slice(n - 2);
                    v = parseInt(v, 16) + 32;
                    v = Buffer.from([v]).toString('hex');
                    result = result.slice(0, n - 2) + v;
                }

                resolve(result);
            }
        }

        if (isMetaMask) {
            // metamask uses  web3.eth.sign to sign transaction and not for arbitrary messages
            // instead use https://medium.com/metamask/scaling-web3-with-signtypeddata-91d6efc8b290
            web3.currentProvider.sendAsync({
                method: 'eth_signTypedData',
                params: [msgParams, my_address],
                from: my_address,
            }, cb)
        } else {
            const msg = sigUtil.typedSignatureHash(msgParams);
            console.log('my_address=' + my_address + ' msg=' + msg);
            if (web3.eth.getSign) {
                web3.eth.getSign(my_address, msg, cb)
            } else {
                // TODO Crazy bug in Web3 in doc it is said that msg should come first https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
                web3.eth.sign(my_address, msg, cb)
            }
        }
    })
}

function sign_me(my_address: string, contractAddress: string, i: number, web3: any): Promise<string> {
    return new Promise((resolve, reject) => {
        if (!web3 || !web3.currentProvider) {
            reject('No web3 instance');
        }
        const {isMetaMask} = web3.currentProvider;

        function cb(err, result) {
            if (err) {
                console.log('Error ' + err);
                reject(err)
            } else {
                const signedPK = typeof result == 'string' ? result : result.result;
                // private_key = web3.sha3(private_key)
                // private_key = private_key.slice(2, 2 + 32 * 2)  // skip the 0x at the begining of signature
                // private_key = Buffer.from(private_key, 'hex')
                resolve(signedPK)
            }
        }

        if (isMetaMask) {
            // metamask uses  web3.eth.sign to sign transaction and not for arbitrary messages
            // instead use https://medium.com/metamask/scaling-web3-with-signtypeddata-91d6efc8b290
            const msgParams = [
                {
                    type: 'string',      // Any valid solidity type
                    name: 'contract address',     // Any string label you want
                    value: contractAddress  // The value to sign
                },
                {
                    type: 'string',
                    name: 'my address',
                    value: my_address
                },
                {
                    type: 'uint32',
                    name: 'nonce',
                    value: i
                },
            ];
            web3.currentProvider.sendAsync({
                method: 'eth_signTypedData',
                params: [msgParams, my_address],
                from: my_address,
            }, cb);

        } else {
            let ii = i.toString(16);
            let msg = '0xdeadbeef' + contractAddress.slice(2) + my_address.slice(2) + ii;
            msg = web3.sha3(msg);

            if (web3.eth.getSign) {
                web3.eth.getSign(my_address, msg, cb);
            } else {
                // TODO Crazy bug in Web3 in doc it is said that msg should come first https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
                web3.eth.sign(my_address, msg, cb);
            }
        }
    })
}

function generateSignatureKeys(
    my_address: string,
    plasma_address: string,
    contractAddress: string,
    web3: any,
): Promise<ISignedKeys> {
    // my_address - return my link and update contract with my public key if necessary (no previous link allowed if I have ARCs)
    // c - contract
    // f_address, f_secret, p_message - previous link (optional if I alredy have ARCs)
    // cut 1..101 or 255 or null

    return new Promise<ISignedKeys>(async (resolve, reject) => {
        if (!web3 || !web3.currentProvider) {
            reject('No web3 instance');
        }
        try {
            // generate random private key exactly as in app.js
            // in the full dApp we need to generate a deterministic private_key when there is no previous link

            // For convenience, make sure we can later recompute the private key it (instead of storing it)
            // so derive the private key from my own ethereum private key (of course without risking it in any way)
            const i = 1;
            const s = await sign_me(my_address, contractAddress, i, web3);
            let private_key = web3.sha3(s);
            private_key = private_key.slice(2, 2 + 32 * 2);
            const public_address = privateToPublic(Buffer.from(private_key, 'hex'));
            resolve({
                private_key,
                public_address,
            })
        } catch (e) {
            reject(e);
        }
    });
}


/**
 *
 * @param web3
 * @param msgParams
 * @param from
 * @param {IOptionalParamsSignMessage} opts
 * @returns {Promise<any>}
 */
function sign_message(web3, msgParams, from, opts: IOptionalParamsSignMessage = {}): Promise<string> {
    return new Promise<string>((resolve, reject) => {
        const {isMetamask = false} = web3.currentProvider;

        function sign_message_callback(err, result) {
            if (err) {
                console.log('Error in sign_message ' + err)
                reject(err)
            } else if (!result) {
                console.log('Error in sign_message no result')
                reject()
            } else {
                if (typeof result != 'string') {
                    result = result.result
                }

                if (opts.plasma || !isMetamask) {
                    let n = result.length;
                    let v = result.slice(n - 2);
                    v = parseInt(v, 16) + 32;
                    v = Buffer.from([v]).toString('hex');
                    result = result.slice(0, n - 2) + v
                }

                resolve(result)
            }
        }

        if (!opts.plasma && isMetamask) {
            assert.ok(typeof msgParams == 'object', 'bad msgParams')
            // metamask uses  web3.eth.sign to sign transaction and not for arbitrary messages
            // instead use https://medium.com/metamask/scaling-web3-with-signtypeddata-91d6efc8b290
            web3.currentProvider.sendAsync({
                method: 'eth_signTypedData',
                params: [msgParams, from],
                from: from,
            }, sign_message_callback)
        } else {
            let hash;
            if (typeof msgParams == 'object') {
                hash = sigUtil.typedSignatureHash(msgParams)
            } else {
                assert.ok(msgParams.startsWith('0x'), 'msgParams not 0x')
                hash = web3.sha3(msgParams)
            }
            if (web3.eth.getSign) {
                web3.eth.getSign(from, hash, sign_message_callback)
            } else {
                console.log("I AM HEREEEE22!")
                web3.eth.sign(from, hash, sign_message_callback)
            }
        }
    })
}

/**
 *
 * @param web3
 * @param my_address
 * @param name
 * @param {IOptionalParamsSignMessage} opts
 * @returns {Promise<any>}
 */
function sign_name(web3, my_address, name, opts: IOptionalParamsSignMessage = {}): Promise<string> {
    let msgParams = [
        {
            type: 'bytes',      // Any valid solidity type
            name: 'binding to name',     // Any string label you want
            value: add0x(Buffer.from(name, 'ascii').toString('hex'))  // The value to sign
        }
    ];
    return sign_message(web3, msgParams, my_address) // we never use metamask on plasma
}


export interface IOptionalParamsSignMessage {
    plasma?: boolean
}

export default {
    sign_ethereum2plasma_note,
    sign_ethereum2plasma,
    sign_plasma2ethereum,
    encrypt,
    decrypt,
    remove0x,
    add0x,
    sign_name,
    free_take,
    free_join,
    free_join_take,
    privateToPublic,
    validate_join,
    generatePrivateKey,
    sign_cut2eteherum,
    generateSignatureKeys,
    sign_plasma2eteherum, //TODO: DEPRECATED
};
