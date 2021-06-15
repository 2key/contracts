const truffleAssert = require('truffle-assertions');
const BigNumber = web3.BigNumber;

async function awaitTx(tx) {
    return await (await tx).wait()
}

async function waitForSomeTime(provider, seconds) {
    await provider.send('evm_increaseTime', [seconds])
}

module.exports = {
    truffleAssert,
    BigNumber,
    awaitTx,
    waitForSomeTime
}