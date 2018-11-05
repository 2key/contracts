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


contract('LiberthonDAO', async(accounts) => {
    let initialMemberAddresses = [accounts[0],accounts[1]];
    let initialMemberUsernames = [fromUtf8("Marko"), fromUtf8("Petar")];
    let initialMemberlastNames = [fromUtf8("Blabla"), fromUtf8("Blabla1")];
    let initialMemberTypes = [fromUtf8("PRESIDENT"),fromUtf8("MINISTER")];

    it('should deploy contract', async() => {
        let libertonDAO = await LiberthonDAO.new(
            'Liberland',
            '0x123456',
            initialMemberAddresses,
            initialMemberUsernames,
            initialMemberUsernames,
            initialMemberlastNames,
            initialMemberTypes
        );
    });

});
