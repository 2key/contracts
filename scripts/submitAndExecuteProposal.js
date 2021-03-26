require('dotenv').config({path:'/.env-congress'});

const EthereumTx = require('ethereumjs-tx');
const Web3 = require('web3');

const util = require('util');

const exec = util.promisify(require('child_process').exec);
const fs = require('fs');

const constants = require('./constants');

const congressPrivate = require('../build/contracts/TwoKeyPlasmaCongress.json');
const congressPrivateAddress = congressPrivate.networks['180'].address;

const address1 = process.env.ADDRESS1;
const privateKey1 = process.env.PK1;

const address2 = process.env.ADDRESS2;
const privateKey2 = process.env.PK2;


const web3 = new Web3(new Web3.providers.HttpProvider(constants.rpcs['master-private']));

web3.eth.defaultAccount = address1;

const congressContract = web3.eth.contract(congressPrivate.abi).at(congressPrivateAddress);

let nonce1 = web3.eth.getTransactionCount(address1);
let nonce2 = web3.eth.getTransactionCount(address2);

const gasPrice = 0;

/**
 *
 * @param beneficiary
 * @param weiAmount
 * @param jobDescription
 * @param transactionBytecode
 * @param address
 * @param pk
 * @returns {Promise<void>}
 */
const submitProposal = async (beneficiary, weiAmount, jobDescription, transactionBytecode, address, pk) => {
  try {
    await sendTransaction(web3, congressContract.newProposal, address, pk,
      [beneficiary, weiAmount, jobDescription, transactionBytecode], gasPrice, web3.toHex(nonce1));
  } catch (err) {
    console.log(err);
  }
}

/**
 *
 * @param proposalNumber
 * @param supportsProposal
 * @param justificationText
 * @param address
 * @returns {Promise<void>}
 */
const voteForProposal = async (proposalNumber, supportsProposal, justificationText, address, pk) => {
  try {
    await sendTransaction(web3, congressContract.vote, address, pk,
      [proposalNumber, supportsProposal, justificationText], gasPrice, web3.toHex(nonce1));
  } catch (err) {
    console.log(err);
  }
}

/**
 *
 * @param proposalNumber
 * @param transactionBytecode
 * @param address
 * @param pk
 * @returns {Promise<void>}
 */
const executeProposal = async (proposalNumber, transactionBytecode, address, pk) => {
  try {
    await sendTransaction(web3, congressContract.executeProposal, address, pk
      [proposalNumber, transactionBytecode], gasPrice, web3.toHex(nonce1));
  } catch (err) {
    console.log(err);
  }
}

/**
 *
 * @param contractMethod
 * @param params
 * @returns {*}
 */
const getEncodedParams = (contractMethod, params = null) => {
  let encodedTransaction = null;
  if (!params) {
    encodedTransaction = contractMethod.request.apply(contractMethod); // eslint-disable-line
  } else {
    encodedTransaction = contractMethod.request.apply(contractMethod, params); // eslint-disable-line
  }
  return encodedTransaction.params[0];
};

/**
 *
 * @param web3
 * @param contractMethod
 * @param from
 * @param params
 * @param _gasPrice
 * @param nonce
 * @returns {Promise<unknown>}
 */
const sendTransaction = async (web3, contractMethod, from, pk, params, _gasPrice, nonce) =>
  new Promise(async (resolve, reject) => {
    try {
      const privateKey = new Buffer(privateKey1, 'hex');

      const { to, data } = getEncodedParams(contractMethod, params);

      const gasPrice = web3.toHex(_gasPrice);

      const gas = web3.toHex(8000000);

      let transactionParams = { from, to, data, gas, gasPrice, nonce };

      const txHash = await sendRawTransaction(web3, transactionParams, privateKey);

      console.log('TxHash: ', txHash);
      resolve(txHash);
    } catch (err) {
      reject(err);
    }
  });

/**
 *
 * @param web3
 * @param transactionParams
 * @param privateKey
 * @returns {Promise<unknown>}
 */
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

  const beneficiary = process.argv[1].toString();
  const weiAmount = 0;
  const jobDescription = process.argv[2].toString();
  const transactionBytecode = process.argv[3].toString();

  await submitProposal(beneficiary, weiAmount, jobDescription, transactionBytecode, address1, privateKey1);
  console.log(`Proposal submitted from ${address1} with nonce: ${nonce1}`);

  nonce1++;

  let proposalId = await congressContract.numProposals();

  await voteForProposal(proposalId.toString(), true, 'I support', address1, privateKey1);
  console.log(`Support vote submitted from ${address1} with nonce: ${nonce1}`);
  nonce1++;

  web3.eth.defaultAccount = address2;

  await voteForProposal(proposalId.toString(), true, 'I support', address2, privateKey2);
  console.log(`Support vote submitted from ${address2} with nonce: ${nonce2}`);
  nonce2++;

  await executeProposal(proposalId, transactionBytecode, address2, privateKey2);
  console.log(`Execute proposal submitted from ${address2} with nonce: ${nonce2}`);
})();
