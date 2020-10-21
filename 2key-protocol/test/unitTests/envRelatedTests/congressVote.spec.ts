import {TwoKeyProtocol} from "../../../src";
import {expect} from "chai";
import web3Switcher from "../../helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "../../helpers/twoKeyProtocol";
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');


let twoKeyProtocol: TwoKeyProtocol;
let from: string;

let transactionBytecode =
    "0x9ffe94d9000000000000000000000000bae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7000000000000000000000000000000000000000000084595161401484a000000";

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
        expect(memberInfo.memberName).to.be.equal('Eitan');
    }).timeout(30000);

    it('should create a proposal', async() => {
        const admin = twoKeyProtocol.twoKeyAdmin;
        let txHash: string = await twoKeyProtocol.Congress.newProposal(
            twoKeyProtocol.twoKeyAdmin.address,
            "Send some tokens to contractor",
            transactionBytecode,
            from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('1. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress } = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('2. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress } = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('3. member vote to support proposal', async() => {
        const {web3, address, plasmaWeb3, plasmaAddress} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress));
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();

        let txHash: string = await twoKeyProtocol.Congress.vote(numberOfProposals-1,true, "I also support sending tokens", from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should get proposal data', async() => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        numberOfProposals = parseFloat(numberOfProposals.toString());
        let data = await twoKeyProtocol.Congress.getProposalInformations(numberOfProposals-1,from);
        expect(data.proposalIsExecuted).to.be.equal(false);
        expect(data.proposalNumberOfVotes).to.be.equal(3);
    }).timeout(60000);

    it('should advance time and execute proposal',async() => {
        let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
        let txHash: string = await twoKeyProtocol.Congress.executeProposal(numberOfProposals-1, transactionBytecode, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);
});



