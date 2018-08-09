const { increaseTime } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');

const HOUR = 3600;

const TwoKeyCongress = artifacts.require("TwoKeyCongress");
const BasicStorage = artifacts.require("BasicStorage");

contract('TwoKeyCongress', async (accounts) => {

    let congress;
    let transactionBytecode;

    before(async () => {
        congress = await TwoKeyCongress.new(60, 51);
        storage = await BasicStorage.new();
        const sig = web3.sha3("set(uint256)").slice(0,10);
        const arg1 = _.repeat("0", 62) + "20";
        transactionBytecode = sig + arg1;
    });
  
    it("congress owned by creator", async () => {      
        let owner = await congress.owner.call();
        assert.equal(owner,  accounts[0], 'account creating the contract is the owner');
    });

    it("add account 1 member", async () => {
        let address = accounts[1];
        let name = 'john doe';
        
        await congress.addMember(address, name, { from: accounts[0] });

        let index = await congress.memberId(address);
        assert.equal(index.toNumber(), 2, 'member not stored');
    });

    it("add account 2 member", async () => {
        let address = accounts[2];
        name = 'benjamin franklin';

        await congress.addMember(address, name, { from: accounts[0] });

        let index = await congress.memberId(address);
        assert.equal(index.toNumber(), 3, 'member was not stored in place');
    });

    it("get member details", async () => {
        let address2 = accounts[2];
        name2 = 'benjamin franklin';

        await congress.addMember(address2, name2, { from: accounts[0] });

        [address, name, timestamp] = await congress.members(3);
        assert.equal(address, address2, 'address not really stored for member');
        assert.equal(name, name2, 'name not reallty stored for member');
    });

    it("remove member account 1", async () => {
        let address1 = accounts[1];

        await congress.removeMember(address1, { from: accounts[0] });

        let index = await congress.memberId(address1);
        assert.equal(index, 0, 'member was not removed');
    });

    it("voting rules setup", async () => {
        let quorom = await congress.minimumQuorum();
        assert.equal(quorom, 60, 'quorom not changed');

        let votingPeriod = await congress.debatingPeriodInMinutes();
        assert.equal(votingPeriod, 51, 'debating period not changed');
    });

    it("change voting rules", async () => {
        await congress.changeVotingRules(40, 20, { from: accounts[0] });

        let quorom = await congress.minimumQuorum.call();
        assert.equal(quorom, 40, 'quorom not changed');

        let votingPeriod = await congress.debatingPeriodInMinutes.call();
        assert.equal(votingPeriod, 20, 'debating period not changed');
    });

    it("make a proposal and check it", async () => {
        await congress.newProposal(
            storage.address, 
            50, 
            'store something', 
            transactionBytecode, { from: accounts[2] });
    
        let flag = await congress.checkProposalCode(
            0, 
            storage.address, 
            50, 
            transactionBytecode.replace());
        assert.isTrue(flag, 'proposal was not checked');

    }); 

    it("if a proposal was never made it will not check", async () => {  
        let t = _.replace(transactionBytecode, '2', '1');

        let flag = await congress.checkProposalCode(
            0, 
            storage.address, 
            50, 
            t);
        assert.isFalse(flag, 'proposal was wrongly checked');

    });     

    it("add member account 5", async () => {
        let address5 = accounts[5];
        let name5 = 'the fifth';

        await congress.addMember(address5, name5, { from: accounts[0] });

        let [address, name, timestamp] = await congress.members(3);
        assert.equal(address, address5, 'address not really stored for member');
        assert.equal(name, name5, 'name not reallty stored for member');

    });

    it("add member account 6", async () => {
        let address6 = accounts[6];
        let name6 = 'six person';

        await congress.addMember(address6, name6, { from: accounts[0] });

        let [member, name, memberSince] = await congress.members(4);

        assert.equal(member, address6);
        assert.equal(name, name6);
    });

    it("account 5 votes yes", async () => {
        let v = await congress.vote(0, true, "it is good to keep things", {
            from: accounts[5]
        });        
        let [numberOfVotes, currentResult] = await congress.getVoteCount.call(0, {
            from: accounts[5]
        });
        assert.equal(numberOfVotes.toNumber(), 1, 'not one vote');
        assert.equal(currentResult.toNumber(), 1, 'not one yay');
    }); 


    it("vote yay account 6", async () => {
        let v6 = await congress.vote(0, true, "yes, is good to keep things", {
            from: accounts[6]
        });
        let [num, cur] = await congress.getVoteCount(0);
        assert.equal(num.toNumber(), 2, 'not two votes');
        assert.equal(cur.toNumber(), 2, 'not two yays');
    });

    it("advance time and execute proposal", async () => {

        await increaseTime(HOUR);

        await congress.send(80, {
            from: accounts[5]
        })

        await congress.executeProposal(0, transactionBytecode, {
            from: accounts[8]
        });

        let storedValue = await storage.get();

        assert.equal(storedValue.toNumber(), 32, "proposal not executed");
    }); 
});
