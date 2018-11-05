const LiberthonDAO = artifacts.require("LiberthonDAO");

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


contract('LiberthonDAO', async(accounts) => {
    let initialMemberAddresses = [accounts[0],accounts[1]];
    let initialMemberUsernames = [fromUtf8("Marko"), fromUtf8("Petar")];
    let initialMemberlastNames = [fromUtf8("Blabla"), fromUtf8("Blabla1")];
    let initialMemberTypes = [fromUtf8("PRESIDENT"),fromUtf8("MINISTER")];
    let instance;
    it('should deploy contract', async() => {
        instance = await LiberthonDAO.new(
            'Liberland',
            '0x123456',
            initialMemberAddresses,
            initialMemberUsernames,
            initialMemberUsernames,
            initialMemberlastNames,
            initialMemberTypes
        );
    });

    it('should return all members', async() => {
        let [membersAddresses, memberUsernames, memberNames, memberLastNames, memberTypes] = await instance.getAllMembers();
        for(let i=0; i<memberUsernames.length; i++) {
            memberUsernames[i] = toUtf8(memberUsernames[i]);
            memberNames[i] = toUtf8(memberNames[i]);
            memberLastNames[i] = toUtf8(memberLastNames[i]);
            memberTypes[i] = toUtf8(memberTypes[i]);
        }

        console.log(memberUsernames);
        console.log(memberTypes);
    })
});
