const DecentralizedNation = artifacts.require("DecentralizedNation");

var utf8 = require('utf8');

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


contract('DecentralizedNation', async(accounts) => {
    let initialMemberAddresses = [accounts[0],accounts[1]];
    let initialMemberUsernames = [fromUtf8("Marko"), fromUtf8("Petar")];
    let initialMemberlastNames = [fromUtf8("Blabla"), fromUtf8("Blabla1")];
    let ipfsHash = fromUtf8("IFSAFNJSDNJF");
    let initialMemberTypes = [fromUtf8("PRESIDENT"),fromUtf8("MINISTER")];
    let instance;
    it('should deploy contract', async() => {
        instance = await DecentralizedNation.new(
            'Liberland',
            '0x123456',
            ipfsHash,
            initialMemberAddresses,
            initialMemberUsernames,
            initialMemberUsernames,
            initialMemberlastNames,
            initialMemberTypes
        );
        console.log(instance.address);
    });

    it('should return all members', async() => {
        let [membersAddresses, memberUsernames, memberNames, memberLastNames, memberTypes] = await instance.getAllMembers();
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
       let memberAddresses = await instance.getAllMembersForType(fromUtf8('FOUNDERS'));
       assert.equal(memberAddresses[0], accounts[0]);
       assert.equal(memberAddresses[1], accounts[1]);
    });


    it('should set limit for number of members per type', async() => {
        initialMemberTypes.push(fromUtf8('FOUNDERS'));
        await instance.setLimitForMembersPerType(initialMemberTypes,[20,30,50]);

        let limit = await instance.getLimitForType(fromUtf8('FOUNDERS'));
        assert.equal(limit, 50);
    });


    it('should return member\'s voting points', async() => {
       let pts = await instance.getMembersVotingPoints(accounts[0]);
       assert.equal(pts,100);
    });

    it('should create authority schema for the member type', async() => {
       let allowedToVoteInChange = [fromUtf8('PRESIDENT'), fromUtf8('FOUNDERS')];
       let numberOfMembers = 50;
       let percentage = 20;

       await instance.createAuthoritySchemaForType(fromUtf8('FOUNDERS'), allowedToVoteInChange,numberOfMembers,percentage);
        let memberEligibleToVoteInChanging,
            minimalNumOfMembers,
            percentageToReach;

       [memberEligibleToVoteInChanging, minimalNumOfMembers,percentageToReach] = await instance.getAuthorityToChangeSelectedMemberType(fromUtf8('FOUNDERS'));
        assert.equal(numberOfMembers,minimalNumOfMembers);
        assert.equal(percentage, percentageToReach);
        for(let i=0; i<memberEligibleToVoteInChanging.length; i++) {
            assert.equal(toUtf8(memberEligibleToVoteInChanging[i]), toUtf8(allowedToVoteInChange[i]));
        }
    });

});
