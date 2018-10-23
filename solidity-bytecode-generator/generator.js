const Web3 = require('./node_modules/web3-eth-abi');
const sha3 = require('js-sha3');
/*
    @Author Nikola Madjarevic
    Javascript library developed with goal to easily generate bytecode for any method you'd like to call
 */


const convertNameAndArgTypes = ((methodName, methodArgumentsTypes) => {
    let signature = methodName + "(";
    for(let i=0; i<methodArgumentsTypes.length; i++) {
        if(i == methodArgumentsTypes.length -1) {
            signature += methodArgumentsTypes[i].toString()+")";
        } else {
            signature += methodArgumentsTypes[i].toString()+ ",";
        }
    }
    signature = sha3.keccak_256(signature).slice(0,10);
    // console.log(sha3.keccak_256(signature));
    return signature;
});


const convertUint = ((value) => {
    let numberOfDigits = value.toString().length;
    let arg = "";
    for(let i=0; i< (64- numberOfDigits); i++) {
        arg += "0";
    }
    arg += value.toString();
    return arg;
});

const convertAddress = ((value) => {
    let prefix = '';
    for(let i=0; i<24; i++) {
        prefix +='0';
    }
    return (prefix + value.substr(2));
});

const convertString = ((value) => {
    let data = Web3.modules('string', value);
    return data;
});

console.log(convertString("marko"));


module.exports = {
    convertNameAndArgTypes,
    convertUint,
    convertAddress,
    convertString,
};