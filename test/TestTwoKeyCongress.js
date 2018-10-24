const { increaseTime } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');
const HOUR = 3600;

var Web3EthAbi = require('web3-eth-abi');

const TwoKeyCongress = artifacts.require("TwoKeyCongress");
const BasicStorage = artifacts.require("BasicStorage");

contract('TwoKeyCongress', async (accounts) => {
    let congress;
    //function addMember(address targetMember, string memberName, int _votingPower)

    let method=  web3.sha3('addMember(address,string,uint256)').slice(0,10);
    console.log("METHOD" + method);

    let functionSignature = Web3EthAbi.encodeFunctionSignature({
        name: 'addMember',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'targetMember'
        }, {
            type: 'string',
            name: 'memberName'
        }, {
            type: 'uint256',
            name: '_votingPower'
        }]
    });
    console.log("Function signature: " + functionSignature);


    let transactionBytecode = Web3EthAbi.encodeFunctionCall({
        name: 'addMember',
        type: 'function',
        inputs: [{
            type: 'address',
            name: 'targetMember'
        }, {
            type: 'string',
            name: 'memberName'
        }, {
            type: 'uint256',
            name: '_votingPower'
        }]
    }, ['0xd03ea8624c8c5987235048901fb614fdca89b117', 'Nikola', '5']);


    let transactionBytecode2 = Web3EthAbi.encodeFunctionSignature({
        name: 'removeMember',
        type: 'function' ,
        inputs: [{
            type: 'address',
            name: 'targetMember'
        }]
    }, [accounts[1]]);


    let initialMembers = [accounts[1], accounts[2]];
    let votingPowers = [1,2];



    before(async () => {
        console.log("Creating new congress contract");
        console.log("Initial members are going to be represented by following addresses: " + initialMembers);
        console.log("Their voting powers will be respectively: "+ votingPowers);
        congress = await TwoKeyCongress.new(1, 55, initialMembers,votingPowers);
        // let membersLength = await congress.getMembersLength({from: accounts[4]});
        // console.log(membersLength);
        storage = await BasicStorage.new();
        console.log("Transaction bytecode is : " + transactionBytecode);

    });

    it('should check max voting power', async() => {
        console.log('Testing max voting power');
        let maxVotingPower = await congress.getMaxVotingPower();
        console.log("Max voting power : " + maxVotingPower)
        assert.equal(maxVotingPower.toNumber(),3, 'is not corect');
    })
    it("should save data" , async() => {
        console.log("Testing on basic contract");
        let bytecode = Web3EthAbi.encodeFunctionCall({
            name: 'myMethod',
            type: 'function',
            inputs: [{
                type: 'uint256',
                name: 'myNumber'
            },{
                type: 'string',
                name: 'myString'
            }]
        }, ['2345675643', 'Hello!']);
        await storage.callFunction(bytecode);

        let data = await storage.get();
        console.log(data);
    });

    it("congress owned by creator", async () => {
        let owner = await congress.owner.call();
        assert.equal(owner,  accounts[0], 'account creating the contract is the owner');
    });

    // // test replacing member
    // it("member should be able to replace his own address", async () => {
    //
    //     let memberId1 = await congress.getMemberId({from:accounts[1]});
    //     let memberId2 = await congress.getMemberId({from:accounts[2]});
    //
    //     console.log(memberId1);
    //     console.log(memberId2);
    //     let memberInfo = await congress.getMemberInfo({from:accounts[1]});
    //     let memberInfo2 = await congress.getMemberInfo({from: accounts[2]});
    //
    //     let replace = await congress.replaceMemberAddress(accounts[3], {from: accounts[1]});
    //
    //
    //     let afterChange = await congress.getMemberInfo({from:accounts[1]});
    //     console.log(afterChange);
    //
    //     let afterAllChanges = await congress.getMemberInfo({from:accounts[3]});
    //     console.log(afterAllChanges)
    // });

    it("should check if voting rules are set", async() => {
        let quorum = await congress.minimumQuorum();
        assert.equal(1,quorum,'quorum should be 60');
        let votingPeriod = await congress.debatingPeriodInMinutes();
        assert.equal(votingPeriod, 55, 'debating period not changed');
    });


    it("make a proposal and check it", async () => {
        await congress.newProposal(
            congress.address,
            0,
            'Add new member',
            transactionBytecode, { from: accounts[2] });

        let flag = await congress.checkProposalCode(
            0,
            congress.address,
            0,
            transactionBytecode.replace());
        assert.isTrue(flag, 'proposal was not checked');
    });

    it("account 1 votes yes", async () => {
        let v = await congress.vote(0, true, "it is good to keep things", {
            from: accounts[1]
        });
        let [numberOfVotes, currentResult] = await congress.getVoteCount.call(0, {
            from: accounts[1]
        });
        assert.equal(numberOfVotes.toNumber(), 1, 'not one vote');
        assert.equal(currentResult.toNumber(), 1, 'not one yay');
    });

    it('account 2 votes yes', async() => {
        let v = await congress.vote(0, true, 'yeee', {from : accounts[2]});
        let [numberOfVotes, currentResult] = await congress.getVoteCount.call(0, {from:accounts[2]});

        assert.equal(numberOfVotes.toNumber(), 2, 'not two votes');
        assert.equal(currentResult.toNumber(), 3, 'not three');
    });


    it("advance time and execute proposal", async () => {

        await increaseTime(HOUR);

        await congress.send(10000, {
            from: accounts[5]
        });

        await congress.executeProposal(0, transactionBytecode, {
            from: accounts[5]
        });

        let data = await congress.getMemberInfo({from: accounts[4]});
        console.log(data);


        let allowedMethods = await congress.getAllowedMethods();
        console.log(allowedMethods);
    });


    // it("vote yay account 6", async () => {
    //     let v6 = await congress.vote(0, true, "yes, is good to keep things", {
    //         from: accounts[2]
    //     });
    //     let [num, cur] = await congress.getVoteCount(0);
    //     assert.equal(num.toNumber(), 2, 'not two votes');
    //     assert.equal(cur.toNumber(), 2, 'not two yays');
    // });

    // it("add account 1 member", async () => {
    //     let address = accounts[1];
    //     let name = 'john doe';
    //
    //     await congress.addMember(address, name, { from: accounts[0] });
    //
    //     let index = await congress.memberId(address);
    //     assert.equal(index.toNumber(), 2, 'member not stored');
    // });
    //
    // it("add account 2 member", async () => {
    //     let address = accounts[2];
    //     name = 'benjamin franklin';
    //
    //     await congress.addMember(address, name, { from: accounts[0] });
    //
    //     let index = await congress.memberId(address);
    //     assert.equal(index.toNumber(), 3, 'member was not stored in place');
    // });
    //
    // it("get member details", async () => {
    //     let address2 = accounts[2];
    //     name2 = 'benjamin franklin';
    //
    //     await congress.addMember(address2, name2, { from: accounts[0] });
    //
    //     [address, name, timestamp] = await congress.members(3);
    //     assert.equal(address, address2, 'address not really stored for member');
    //     assert.equal(name, name2, 'name not reallty stored for member');
    // });
    //
    // it("remove member account 1", async () => {
    //     let address1 = accounts[1];
    //
    //     await congress.removeMember(address1, { from: accounts[0] });
    //
    //     let index = await congress.memberId(address1);
    //     assert.equal(index, 0, 'member was not removed');
    // });
    //


    //
    // it("make a proposal and check it", async () => {
    //     await congress.newProposal(
    //         storage.address,
    //         50,
    //         'store something',
    //         transactionBytecode, { from: accounts[2] });
    //
    //     let flag = await congress.checkProposalCode(
    //         0,
    //         storage.address,
    //         50,
    //         transactionBytecode.replace());
    //     assert.isTrue(flag, 'proposal was not checked');
    //
    // });
    //
    // it("if a proposal was never made it will not check", async () => {
    //     let t = _.replace(transactionBytecode, '2', '1');
    //
    //     let flag = await congress.checkProposalCode(
    //         0,
    //         storage.address,
    //         50,
    //         t);
    //     assert.isFalse(flag, 'proposal was wrongly checked');
    //
    // });
    //
    // it("add member account 5", async () => {
    //     let address5 = accounts[5];
    //     let name5 = 'the fifth';
    //
    //     await congress.addMember(address5, name5, { from: accounts[0] });
    //
    //     let [address, name, timestamp] = await congress.members(3);
    //     assert.equal(address, address5, 'address not really stored for member');
    //     assert.equal(name, name5, 'name not reallty stored for member');
    //
    // });
    //
    // it("add member account 6", async () => {
    //     let address6 = accounts[6];
    //     let name6 = 'six person';
    //
    //     await congress.addMember(address6, name6, { from: accounts[0] });
    //
    //     let [member, name, memberSince] = await congress.members(4);
    //
    //     assert.equal(member, address6);
    //     assert.equal(name, name6);
    // });
    //



});
