const DecentralizedNation = artifacts.require("DecentralizedNation");
const TwoKeyVoteToken = artifacts.require("TwoKeyVoteToken");
const TwoKeyWeightedVoteContract = artifacts.require("TwoKeyWeightedVoteContract");
const TwoKeyReg = artifacts.require("TwoKeyReg.sol");
const TwoKeyPlasmaEvents = artifacts.require("TwoKeyPlasmaEvents");
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
    let initialMemberFullNames = ["Marko Ivanovic", "Petar Petrovic"];
    let initialMembersEmails = ["nikola@2key.com", "kiki@2key.com"];
    let ipfsHash = fromUtf8("IFSAFNJSDNJF");
    let initialMemberTypes = [fromUtf8("PRESIDENT"),fromUtf8("MINISTER")];
    let plasmaEvents;

    let manyMemberAddresses = [
            accounts[2],
            accounts[3],
            accounts[4],
            accounts[6],
            accounts[7],
            accounts[8],
            accounts[9]];
    let limits = [10,10];
    let manyMembersUsernames = ["Nikola","Andrii","SAndrii","Udi","Kiki", "Yoram", "Mark"];
    let manyMemberEmails = ["nikola@2key.com",
                            "andrii@2key.com",
                            "sandrii2key.com",
                            "udi@2key.com",
                            "kiki@2key.com",
                            "yoram@2key.com",
                            "mark@2key.com",
    ];

    let decentralizedNationInstance;
    let voteToken;
    let weightedVoteContract;
    let twoKeyRegistryContract;

    // it('should deploy plasma contract', async() => {
    //
    //     plasmaEvents = await TwoKeyPlasmaEvents.new();
    // });
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
               initialMemberFullNames[i],
               initialMembersEmails[i],
               {
                   from: accounts[5]
               }
           );
       }
       for(let j=0; j<manyMemberAddresses.length; j++) {
           await twoKeyRegistryContract.addName(
               manyMembersUsernames[j],
               manyMemberAddresses[j],
               manyMembersUsernames[j],
               manyMemberEmails[j],
               {
                   from: accounts[5]
               }
           )
       }
    });


    it('should deploy contract', async() => {
        decentralizedNationInstance = await DecentralizedNation.new(
            'Liberland',
            '0x123456',
            ipfsHash,
            initialMemberAddresses,
            initialMemberTypes,
            limits,
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


    // it('should set limit for number of members per type', async() => {
    //     initialMemberTypes.push(fromUtf8('FOUNDERS'));
    //     await decentralizedNationInstance.setLimitForMembersPerType(initialMemberTypes,[20,30,50]);
    //
    //     let limit = await decentralizedNationInstance.getLimitForType(fromUtf8('FOUNDERS'));
    //     assert.equal(limit, 50);
    // });


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
        // let balanceOfMembers = await voteToken.balanceOf(accounts[0]);
        // assert.equal(balanceOfMembers,100);
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

    it('founders should add members without voting', async() => {
        let newMemberAddress = accounts[7];
        let newMemberType = fromUtf8('PRESIDENT');

        await decentralizedNationInstance.addMembersByFounders(newMemberAddress,newMemberType, {from: accounts[0]});

        let memberAddress,
            username,
            fullName,
            email,
            memberType;

        [memberAddress, username,fullName,email, memberType] = await decentralizedNationInstance.members(3);

        console.log(toUtf8(username));
        console.log(toUtf8(fullName));
        console.log(toUtf8(email));
        console.log(toUtf8(memberType));
    });

    it('should return addresses', async() => {
        await weightedVoteContract.setPublicLinkKey('0x782f2dfbecf08896f0767bfa190d3874ff41e578');
        let addresses = await weightedVoteContract.transferSig('0x0190f8bf6a479f320ead074411a4b0e7944ea8c9c1aabf851c49b4b7e1beeee0c0bcd6324f9fb26eb4f7b7cb9d3ce140ccb1d32c4b3c83e2bf78944e3870c85192359966e50b76087789e1201ce7212134698cd81f1c652b5e72c3361c5deae957eacf4b5122d1f16cf156114b304e83e707dfa04b1ae54fb55a701efb70facf1de92fd83b080b427dff2111ba121e6233dd2b468c995920540ecea1a566271ce22ffd1164e4808a50126f5cef4731514505aa3ec66aa16e8b285728d7916dfbfceba7391698c4a03b7919754c3651e63a04c35b01410d7877e11a81d41b69aca87e9de00a13aadedb96f8e01c1f11fc8a5234ec5b9a2c244406907df80488ed51964d9fd3ed7304f9ab383315fd7f440f7f05d0cc979560610600f35d170fcb0c5fc725f113eca6a9d576da7fc220756ddacfcd525b31bc13f2f65a7e6a7ef5752e89');


        let votedYes = await weightedVoteContract.voted_yes();
        console.log(votedYes);

        let votedNo = await weightedVoteContract.voted_no();
        console.log(votedNo);

        addresses = await weightedVoteContract.transferSig('0x0190f8bf6a479f320ead074411a4b0e7944ea8c9c1ecb4c13502f09f8cb5ef2c832d7b629d7b0cb056a3349233b8feb593e9e4550e420cbbfd5b0b160bdf52b44621be72d0eb1f3df2a4818677ac0ea165723f5cd41ccdf331900d06b5c02485570d733cb928354eca69857850802280320560b01c44cd3c02c32fa9028cf616dd92a47117abd152adfaa29aa097373024f95de3af53642116568a2453d4f8a91a3efa8b9854e10c6da29d59');

        votedYes = await weightedVoteContract.voted_yes();
        console.log(votedYes);

        votedNo = await weightedVoteContract.voted_no();
        console.log(votedNo);

        let weightedyes = await weightedVoteContract.weighted_yes();
        console.log(weightedyes.toNumber());

        let weightedNo = await weightedVoteContract.weighted_no();
        console.log(weightedNo.toNumber());

    })
    // it('should get votes', async() => {
    //     let contractor = accounts[0];
    //     let coinbase_link = await free_join (contractor, contractor, weightedVoteContract, contractor)
    // })


});


