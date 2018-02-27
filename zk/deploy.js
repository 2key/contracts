Web3 = require('web3')

url = 'http://localhost:8545'
var web3 = new Web3(new Web3.providers.HttpProvider(url))

var fs = require('fs')
code = fs.readFileSync('contracts/Verifier.sol').toString()
solc = require('solc')
compiledCode = solc.compile(code)

console.log(compiledCode.contracts[':Verifier'].interface)
abiDefinition = JSON.parse(compiledCode.contracts[':Verifier'].interface)
VerifierContract = web3.eth.contract(abiDefinition)
byteCode = compiledCode.contracts[':Verifier'].bytecode
VerifierContract.new({data: byteCode, from: web3.eth.accounts[0], gas: 5000000})
