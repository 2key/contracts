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

async function free_join (my_address, c, contractor, cut, cut_sign, f_address, f_secret, p_message) {
    // my_address - return my link and update contract with my public key if necessary (no previous link allowed if I have ARCs)
    // c - contract
    // f_address, f_secret, p_message - previous link (optional if I alredy have ARCs)
    // cut 1..101 or 255 or null OR 154 < cut && cut < 255 (1=>0 101=>100 254=>-1 155=>-100)

    // generate random private key exactly as in app.js
    let private_key
    let public_address
    // in the full dApp we need to generate a deterministic private_key when there is no previous link
    let deterministic = true
    if (deterministic) {
        // For convenience, make sure we can later recompute the private key it (instead of storing it)
        // so derive the private key from my own ethereum private key (of course without risking it in any way)
        let i = 1
        let s = await sign_me(my_address, c.address, i)
        private_key = web3.sha3(s)
        private_key = private_key.slice(2, 2 + 32 * 2)
        public_address = sign.privateToPublic(Buffer.from(private_key, 'hex'))
    } else {
        private_key = crypto.randomBytes(32)
        public_address = sign.privateToPublic(private_key)
        private_key = private_key.toString('hex')
    }

    let new_message
    if (f_address) {
        new_message = sign.free_join(my_address, public_address, f_address, f_secret, p_message, cut, cut_sign)
    } else {
        public_address = '0x' + public_address
        await c.setPublicLinkKey(public_address,  {from: my_address, gas: 80000})
        if (cut != null) {
            await c.setCut(cut-1,  {from: my_address, gas: 80000})  // in setCut we use real cut values
        }
    }
    return [my_address, private_key, new_message]  // new link [f_address, f_secret, p_message]
}
module.exports = {
    toUtf8,
    fromUtf8,
    free_join
}