import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import web3Switcher from "./helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "./helpers/twoKeyProtocol";
const { env } = process;
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');


let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const buildBytecode = (receiverAddress: string) => {
    let firstPart = '0x9ffe94d9000000000000000000000000'
    let thirdPart = '000000000000000000000000000000000000000000084595161401484a000000';

    return firstPart+receiverAddress.slice(2)+thirdPart;
};
let transactionBytecodeTransferTokens =
    "0x9ffe94d9000000000000000000000000bae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7000000000000000000000000000000000000000000084595161401484a000000";

let transactionBytecodeUpgradeContract =
    "0x4895392900000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000001854776f4b657955706772616461626c6545786368616e676500000000000000000000000000000000000000000000000000000000000000000000000000000003312e310000000000000000000000000000000000000000000000000000000000";


describe('Start and execute voting' , () => {
    it('should check if bytecode is well created', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);
        let contractor = '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
        let bytecode = buildBytecode(contractor);
        expect(bytecode).to.be.equal(transactionBytecodeTransferTokens);
    }).timeout(60000);

    it('should create a proposal', async() => {
        let txHash: string = await twoKeyProtocol.Congress.newProposal(
            twoKeyProtocol.twoKeyAdmin.address,
            "Send some tokens to contractor",
            transactionBytecodeTransferTokens,
            from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('1. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));

        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('2. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_AYDNEP));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('3. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_GMAIL));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should advance time and execute proposal',async() => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.executeProposal(numberOfProposals-1, transactionBytecodeTransferTokens, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should upgrade contract', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));

        let txHash = await twoKeyProtocol.SingletonRegistry.setContractImplementationByContractNameAndVersion("TwoKeyUpgradableExchange", "1.1", twoKeyProtocol.twoKeyUpgradableExchange.address, from);
    }).timeout(60000);

    it('should create a proposal', async() => {
        let txHash: string = await twoKeyProtocol.Congress.newProposal(
            twoKeyProtocol.twoKeySingletonesRegistry.address,
            "Upgrade contract to new version",
            transactionBytecodeUpgradeContract,
            from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('1. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));

        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support upgrading contracts", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('2. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support upgrading contracts", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('3. member vote to support proposal', async() => {
        const {web3, address} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support upgrading contracts", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should advance time and execute proposal',async() => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.executeProposal(numberOfProposals-1, transactionBytecodeUpgradeContract, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

});



