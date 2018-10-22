const Web3 = require('web3');
const sha3 = require('js-sha3');
/*
    @Author Nikola Madjarevic
    Javascript library developed with goal to easily generate bytecode for any method you'd like to call
 */

/*
    Example:
    function doSomething(address x, string y, uint z) {}
    methodName = "doSomething"
    methodArgumentsTypes = [address, string, uint]
    arguments
*/

/*
    Will be representing of solidity method we'd like to call
 */
let methodName;

/*
    Will be representing all types of parameters we're passing to the method
 */
let methodArgumentsTypes = [];

/*
    Will be representing all concrete values of arguments
 */
let argumentsValues = [];


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
    if(value.length != 42) {
        return -1;
    }
    let prefix = '';
    for(let i=0; i<24; i++) {
        prefix +='0';
    }
    const convertedAddress = prefix + value.substr(2);
    return convertedAddress;
});

const convertString = ((value) => {
    let data = Web3.utils.utf8ToHex(value);
    return value;
});

let signature = convertNameAndArgTypes("getVoteCount",["uint"]);
let arg1 = convertUint(1);

signature = signature + arg1;
console.log(signature);

module.exports = {
    convertNameAndArgTypes,
    convertUint,
    convertAddress,
    convertString,
}