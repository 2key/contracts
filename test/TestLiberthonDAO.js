const DecentralizedNation = artifacts.require("DecentralizedNation");
const TwoKeyVoteToken = artifacts.require("TwoKeyVoteToken");
const TwoKeyWeightedVoteContract = artifacts.require("TwoKeyWeightedVoteContract");
const TwoKeyReg = artifacts.require("TwoKeyReg.sol");
const { increaseTime } = require("./utils");
const utf8 = require('utf8');



var fromUtf8 = function(str, allowZero) {
    str = utf8.encode(str);
    var hex = "";
    for(var i = 0; i < str.length; i++) {
        var code = str.charCodeAt(i);
        if (code === 0) {
            if (allowZero) {
                hex += '00';
            } else {
                break;
            }
        } else {
            var n = code.toString(16);
            hex += n.length < 2 ? '0' + n : n;
        }
    }

    return "0x" + hex;
};

var toUtf8 = function(hex) {
// Find termination
    var str = "";
    var i = 0, l = hex.length;
    if (hex.substring(0, 2) === '0x') {
        i = 2;
    }
    for (; i < l; i+=2) {
        var code = parseInt(hex.substr(i, 2), 16);
        if (code === 0)
            break;
        str += String.fromCharCode(code);
    }

    return utf8.decode(str);
};

contract('DecentralizedNation', async(accounts,deployer) => {

    let initialMemberAddresses = [accounts[0],accounts[1]];
    let initialMemberUsernames = ["Marko", "Petar"];
    let initialMembersEmails = ["nikola@2key.com", "kiki@2key.com"];
    let ipfsHash = fromUtf8("IFSAFNJSDNJF");
    let initialMemberTypes = [fromUtf8("PRESIDENT"),fromUtf8("MINISTER")];

    let decentralizedNationInstance;
    let voteToken;
    let weightedVoteContract;
    let twoKeyRegistryContract;

    it('should deploy registry contract', async() => {
        twoKeyRegistryContract = await TwoKeyReg.new(
            '0x0', '0x0', accounts[5]
        );
        console.log(twoKeyRegistryContract.address);
    });

    it('should register some members to registry', async() => {
       for(let i=0; i<initialMemberAddresses.length; i++) {
           await twoKeyRegistryContract.addName(
               initialMemberUsernames[i],
               initialMemberAddresses[i],
               initialMemberUsernames[i],
               initialMembersEmails[i],
               {
                   from: accounts[5]
               }
           );
       }
    });


    it('should deploy contract', async() => {
        decentralizedNationInstance = await DecentralizedNation.new(
            'Liberland',
            '0x123456',
            ipfsHash,
            initialMemberAddresses,
            initialMemberTypes,
            twoKeyRegistryContract.address
        );
    });

    it('should return all members', async() => {
        let [membersAddresses, memberUsernames, memberNames, memberLastNames, memberTypes] = await decentralizedNationInstance.getAllMembers();
        for(let i=0; i<memberUsernames.length; i++) {
            memberUsernames[i] = toUtf8(memberUsernames[i]);
            memberNames[i] = toUtf8(memberNames[i]);
            memberLastNames[i] = toUtf8(memberLastNames[i]);
            memberTypes[i] = toUtf8(memberTypes[i]);
        }
        assert.equal(memberUsernames[0],'Marko');
        assert.equal(memberTypes[0], 'FOUNDERS');
    });

    it('should return all members with specific type', async() => {
       let memberAddresses = await decentralizedNationInstance.getAllMembersForType(fromUtf8('FOUNDERS'));
       assert.equal(memberAddresses[0], accounts[0]);
       assert.equal(memberAddresses[1], accounts[1]);
    });


    it('should set limit for number of members per type', async() => {
        initialMemberTypes.push(fromUtf8('FOUNDERS'));
        await decentralizedNationInstance.setLimitForMembersPerType(initialMemberTypes,[20,30,50]);

        let limit = await decentralizedNationInstance.getLimitForType(fromUtf8('FOUNDERS'));
        assert.equal(limit, 50);
    });


    it('should return member\'s voting points', async() => {
       let pts = await decentralizedNationInstance.getMembersVotingPoints(accounts[0]);
       assert.equal(pts,100);
    });

    it('should create authority schema for the member type', async() => {
       let allowedToVoteInChange = [fromUtf8('PRESIDENT'), fromUtf8('FOUNDERS')];
       let numberOfMembers = 50;
       let percentage = 20;

       await decentralizedNationInstance.createAuthoritySchemaForType(fromUtf8('FOUNDERS'), allowedToVoteInChange,numberOfMembers,percentage);
        let memberEligibleToVoteInChanging,
            minimalNumOfMembers,
            percentageToReach;

       [memberEligibleToVoteInChanging, minimalNumOfMembers,percentageToReach] = await decentralizedNationInstance.getAuthorityToChangeSelectedMemberType(fromUtf8('FOUNDERS'));
        assert.equal(numberOfMembers,minimalNumOfMembers);
        assert.equal(percentage, percentageToReach);
        for(let i=0; i<memberEligibleToVoteInChanging.length; i++) {
            assert.equal(toUtf8(memberEligibleToVoteInChanging[i]), toUtf8(allowedToVoteInChange[i]));
        }
    });

    it('should deploy TwoKeyVoteToken and see the balances', async() => {
        voteToken = await TwoKeyVoteToken.new(decentralizedNationInstance.address);
        let balanceOfMembers = await voteToken.balanceOf(accounts[0]);
        assert.equal(balanceOfMembers,100);
    });


    it('should start voting for national campaign', async() => {
        let description = "Member Nikola to change his role to president";
        let memberToChangeRole = accounts[1];
        let newRole = initialMemberTypes[0];
        let lengthInDays = 2;

        weightedVoteContract = await TwoKeyWeightedVoteContract.new(description, decentralizedNationInstance.address);
        await decentralizedNationInstance.startVotingForChanging(
            description,
            memberToChangeRole,
            newRole,
            lengthInDays,
            weightedVoteContract.address
           );

        let nvcAddress = await decentralizedNationInstance.nationalVotingCampaigns(0);
        assert.equal(nvcAddress,weightedVoteContract.address);

        let nvc = await decentralizedNationInstance.votingContractAddressToNationalVotingCampaign(nvcAddress);
        // console.log(nvc);
    });

    it('should be able to fetch and execute results', async() => {
        let result = await decentralizedNationInstance.getResultsForVoting(0);
    });

    it('should advance time and execute voting with all validations', async() => {
        const TEN_DAYS = 864000;
        increaseTime(TEN_DAYS);

        await decentralizedNationInstance.executeVoting(0,0);
    });


});


