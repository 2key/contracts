import {TwoKeyProtocol} from "../../../src";
import {expect} from "chai";
import web3Switcher from "../../helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "../../helpers/twoKeyProtocol";
import {promisify} from "../../../src/utils/promisify";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');


let twoKeyProtocol: TwoKeyProtocol;
let from: string;

let transactionBytecode =
    "0x9ffe94d9000000000000000000000000bae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7000000000000000000000000000000000000000000084595161401484a000000";

let transactionBytecodeForSignatoryAddress =
    "0x0772bf91000000000000000000000000a916227584a55cfe94733f03397ce37c0a0f7a74";
describe('TwoKeyCongress contract basic proposal creation, voting, and proposal execution counter.' , () => {

    it('should get all members from congress', async() => {
        const {web3, address, plasmaAddress, plasmaWeb3 } = web3Switcher.deployer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);
        let members = await twoKeyProtocol.CongressMembersRegistry.getAllMembersForCongress(from);
        expect(members.length).to.be.equal(4);
    }).timeout(30000);

    it('should get member info from congress', async() => {
        let memberInfo = await twoKeyProtocol.CongressMembersRegistry.getMemberInfo(from);
        console.log('memberInfo', memberInfo);
        expect(memberInfo.memberName).to.be.equal('Eitan');
    }).timeout(30000);

    it('should create a proposal', async() => {
        let txHash: string = await twoKeyProtocol.Congress.newProposal(
            twoKeyProtocol.twoKeyAdmin._address,
            "Send some tokens to contractor",
            transactionBytecode,
            from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.true;
    }).timeout(60000);

    it('1. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress } = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.true;
    }).timeout(60000);

    it('2. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress } = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.true;
    }).timeout(60000);

    it('3. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.true;
    }).timeout(60000);

    it('should get proposal data', async() => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        numberOfProposals = parseFloat(numberOfProposals.toString());
        let data = await twoKeyProtocol.Congress.getProposalInformations(numberOfProposals-1,from);
        console.log('DATA', data);
        expect(data.proposalIsExecuted).to.be.equal(false);
        expect(data.proposalNumberOfVotes).to.be.equal(3);
    }).timeout(60000);

    it('should advance time and execute proposal', async () => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.executeProposal(numberOfProposals - 1, transactionBytecode, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should create a proposal for setting signatory address', async () => {
        let txHash: string = await twoKeyProtocol.Congress.newProposal(
            twoKeyProtocol.twoKeyParticipationMiningPool.address,
            "Set signatory address to be : 0xa916227584A55CfE94733F03397cE37c0a0f7A74",
            transactionBytecodeForSignatoryAddress,
            from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('1. member vote to support proposal for setting signatory address', async () => {
        const {web3, address, plasmaWeb3, plasmaAddress} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals - 1, true, "I support setting signatory address", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('2. member vote to support proposal', async () => {
        const {web3, address, plasmaWeb3, plasmaAddress} = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals - 1, true, "I support setting signatory address", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.true;
    }).timeout(60000);

    it('3. member vote to support proposal', async () => {
        const {web3, address, plasmaWeb3, plasmaAddress} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals - 1, true, "I support setting signatory address", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should get proposal data for setting signatory address', async () => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        numberOfProposals = parseFloat(numberOfProposals.toString());
        let data = await twoKeyProtocol.Congress.getProposalInformations(numberOfProposals - 1, from);
        expect(data.proposalIsExecuted).to.be.equal(false);
        expect(data.proposalNumberOfVotes).to.be.equal(3);
    }).timeout(60000);

    it('should advance time and execute proposal for setting signatory address', async () => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.executeProposal(numberOfProposals - 1, transactionBytecodeForSignatoryAddress, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should check that signatory address is properly set on the contracts', async () => {
        let signatoryAddressPublic = await twoKeyProtocol.TwoKeyParticipationMiningPool.getSignatoryAddressPublic();
        expect(signatoryAddressPublic.toLowerCase()).to.be.equal(process.env.NIKOLA_ADDRESS.toLowerCase());
    }).timeout(60000);

    it('should create a proposal on plasma congress to add signatory address', async () => {
        let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.newProposal, [
            twoKeyProtocol.twoKeyPlasmaParticipationRewards.address,
            0,
            "Add signatory address",
            transactionBytecodeForSignatoryAddress,
            {
                from: twoKeyProtocol.plasmaAddress
            }
        ]);

        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3});
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should member 1. vote for supporting proposal', async () => {
        let numberOfProposals = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.numProposals, []);
        numberOfProposals = parseInt(numberOfProposals, 10) - 1;

        let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.vote, [
            numberOfProposals,
            true,
            "I support to add signatory address",
            {
                from: twoKeyProtocol.plasmaAddress,
            }
        ]);

        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3});
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should member 2. vote for supporting proposal', async () => {
        const {web3, address, plasmaAddress, plasmaWeb3} = web3Switcher.aydnep();

        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, plasmaWeb3, plasmaAddress);

        let numberOfProposals = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.numProposals, []);
        numberOfProposals = parseInt(numberOfProposals, 10) - 1;

        let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.vote, [
            numberOfProposals,
            true,
            "I support to add signatory address",
            {
                from: twoKeyProtocol.plasmaAddress
            }
        ]);

        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3});
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should execute proposal for adding signatory address on plasma', async () => {
        let numberOfProposals = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.numProposals, []);
        numberOfProposals = parseInt(numberOfProposals, 10) - 1;

        let txHash: string = await promisify(twoKeyProtocol.twoKeyPlasmaCongress.executeProposal, [
            numberOfProposals,
            transactionBytecodeForSignatoryAddress,
            {
                from: twoKeyProtocol.plasmaAddress,
                gas: 7000000
            }
        ]);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3});
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should check that signatory address is properly set on the contracts', async () => {
        let signatoryAddressPlasma = await twoKeyProtocol.TwoKeyParticipationMiningPool.getSignatoryAddressPlasma();
        expect(signatoryAddressPlasma.toLowerCase()).to.be.equal(process.env.NIKOLA_ADDRESS.toLowerCase());
    }).timeout(60000);
});



