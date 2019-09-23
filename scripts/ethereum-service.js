require('dotenv').load();

const EthereumTx = require('ethereumjs-tx');
const Web3 = require('web3');

const util = require('util');

const exec = util.promisify(require('child_process').exec);
const fs = require('fs');

const conf = require('./');
const testContractAddress = conf.metadataContract.address;

const ourAddress = process.env.ADDRESS;
const ourPrivateKey = process.env.PRIV_KEY;

const web3 = new Web3(new Web3.providers.HttpProvider("https://kovan.decenter.com"));
web3.eth.defaultAccount = ourAddress;

const metadataContract = web3.eth.contract(conf.metadataContract.abi).at(testContractAddress);

let nonce = web3.eth.getTransactionCount(ourAddress);

const gasPrice = 1502509001;

const addCard = async (rarity, hashFunction, size, ipfsHash, artist) => {

    try {
        await sendTransaction(web3, metadataContract.addCardMetadata, ourAddress,
            [rarity, ipfsHash, hashFunction, size, artist], gasPrice, web3.toHex(nonce));

        nonce++;
    } catch (err) {
        console.log(err);
    }
}

const getEncodedParams = (contractMethod, params = null) => {
    let encodedTransaction = null;
    if (!params) {
        encodedTransaction = contractMethod.request.apply(contractMethod); // eslint-disable-line
    } else {
        encodedTransaction = contractMethod.request.apply(contractMethod, params); // eslint-disable-line
    }
    return encodedTransaction.params[0];
};

const sendTransaction = async (web3, contractMethod, from, params, _gasPrice, nonce) =>
    new Promise(async (resolve, reject) => {
        try {
            const privateKey = new Buffer(ourPrivateKey, 'hex');

            const { to, data } = getEncodedParams(contractMethod, params);

            const gasPrice = web3.toHex(_gasPrice);

            const gas = web3.toHex(1190000);

            let transactionParams = { from, to, data, gas, gasPrice, nonce };

            const txHash = await sendRawTransaction(web3, transactionParams, privateKey);

            console.log(txHash);

            resolve(txHash);
        } catch (err) {
            reject(err);
        }
    });

const sendRawTransaction = (web3, transactionParams, privateKey) =>
    new Promise((resolve, reject) => {
        const tx = new EthereumTx(transactionParams);

        tx.sign(privateKey);

        const serializedTx = `0x${tx.serialize().toString('hex')}`;

        web3.eth.sendRawTransaction(serializedTx, (error, transactionHash) => {
            console.log("Err: ", error);
            if (error) reject(error);

            resolve(transactionHash);
        });
    });


(async () => {

    if (process.argv.length < 3) {
        console.log('Need more arguments');
    }

    const command = process.argv[2];

    if (command === 'add') {

        const path = process.argv[3];
        const artist = process.argv[4];

        const card = require(path);

        const { stdout, stderr } = await exec('ipfs add -q ./images/' + card['1'].image);

        const ipfsHashes  = stdout.split('\n');

        const imgHash = ipfsHashes[0];

        card['1'].img = imgHash;

        let finalHash = '';

        fs.writeFile(`${path}`, JSON.stringify(card), async (err) => {
            if (!err) {
                const { stdout, stderr } = await exec(`ipfs add -q ${path}`);

                finalHash = stdout.split('\n')[0];

                const { hashFunction, size, ipfsHash } = deconstructIpfsHash(finalHash);

                console.log(card['1'].rarityScore, hashFunction, size, ipfsHash, artist);

                await addCard(card['1'].rarityScore, hashFunction, size, ipfsHash, artist);
            } else {
                console.log(err);
            }
        });

    } else if (command === 'mock') {
        const rarity = process.argv[3];

        await addCard(rarity, '0x0', '0x0', '0x0', '0x0');

    }
})();
