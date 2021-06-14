const truffleAssert = require('truffle-assertions');
const BigNumber = require("bignumber.js");

async function awaitTx(tx) {
    return await (await tx).wait()
}

async function waitForSomeTime(provider, seconds) {
    await provider.send('evm_increaseTime', [seconds])
}

const decimals = "1000000000000000000"; // 1e18

function toTokenAmountWithDecimals (x) {
    return new BigNumber(x * decimals);
}

module.exports = {
    truffleAssert,
    BigNumber,
    awaitTx,
    waitForSomeTime,
    toTokenAmountWithDecimals
}