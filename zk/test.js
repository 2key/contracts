Web3 = require('web3')
BigNumber = require('bignumber.js')
contract = require('truffle-contract')

url = 'http://localhost:8545';
var web3 = new Web3(new Web3.providers.HttpProvider(url));

var fs = require("fs");
code = fs.readFileSync('contracts/Verifier.sol').toString();
solc = require('solc');
compiledCode = solc.compile(code);


abiDefinition = JSON.parse(compiledCode.contracts[':Verifier'].interface);
VerifierContract = web3.eth.contract(abiDefinition);
byteCode = compiledCode.contracts[':Verifier'].bytecode;
deployedContract = VerifierContract.new({data: byteCode, from: web3.eth.accounts[0], gas: 4700000})

// WAIT
setTimeout(()=> {
    console.log('contract address ' + deployedContract.address);
    contractInstance = VerifierContract.at(deployedContract.address);

    var event = contractInstance.Verified()

    // watch for changes
    event.watch(function(error, result){
      if (error) {
          console.log(error);
      } else {
        console.log('Event ' + result.event + ' ' + result.args[0]);
      }
      event.stopWatching();
    });

    params = {
        'gasPrice': 20000000000,
        'gas': 4000000,
        'from': web3.eth.accounts[0],
    }

    A = [new BigNumber('0x29f9853426bf2b836a70d3be44964c05a84464f7f85a56a336bcf70c19fbd010'), new BigNumber('0x1b1e8c097c5dd8cda6148576bc673524978067cfabb8f49f092e56bbb858e346')];
    A_p = [new BigNumber('0x90c6f9009f58e1bb97b7b632c576c6b5d2a83a41f8723441c09a11a11940115'), new BigNumber('0x152a841d9cd5bf59ac17505214b5b05705c11e745b992560e22e32a5ada86b5c')];
    B = [[new BigNumber('0x86ec9cc00b385bde77b5ffcc9152b0fa0e5d5c8264564f2bec019e17280ffcd'), new BigNumber('0x8ce644278b7822684f2da1edf844fa2e7b0817c98894a2b0019968ab50189bd')], [new BigNumber('0x8190cd0682e845c866829f3e0394d8ef8968076f94f57221005fb1a6db1c42b'), new BigNumber('0x2eb34bc7356d6c09c15da637a447924ab652ae5268e731c5b8702a013156d17f')]];
    B_p = [new BigNumber('0x4e67ae33e8ec47665dabd3c8fa3f23ccf4d633c8a113c992b29bff91867dfd7'), new BigNumber('0x16cf2d09cd5629058dae600797e4c215c984423051eb7da82f32b43fcc3ae0d5')];
    C = [new BigNumber('0x19371ab41546b127c3b032c103e58591174d60fd0b4f07c093062b80610fb64f'), new BigNumber('0x25274a03e51cf440080f9c80dd936718cf1412f2335a19738252a25be75e1575')];
    C_p = [new BigNumber('0x9de11f54b285e1f05c859d580ab1bbb389f8ed1d3d17efe694327554950ab8c'), new BigNumber('0x2bcdc1d2eadd7e6a8690eedf8c9e7fd54038496e4b6db882461ad025c441dc07')];
    H = [new BigNumber('0x250a28ddffb23103e2ba0d038064c76453d34aa16cb561e4f655e7172c8cc1ca'), new BigNumber('0x10e41e3a7d489b052b7a48ad1495931742d0d9972b822bcd9f2a97a2d8825a9d')];
    K = [new BigNumber('0x1acba617e605cb2cf003479cdc9877fee12e28e02378afe0ab94cc9f8175f192'), new BigNumber('0x26b989a024ee8436ed0909dcadf9c03eaa26f0c949798ff3a440fc59b852d413')];

// Correct input
    I = [new BigNumber('5'), new BigNumber('1'), new BigNumber('5'), new BigNumber('0'), 1];

//     A = [new BigNumber('0x1628f3170cc16d40aad2e8fa1ab084f542fcb12e75ce1add62891dd75ba1ffd7'), new BigNumber('0x11b20d11a0da724e41f7e2dc4d217b3f068b4e767f521a9ea371e77e496cc54')]
//     A_p = [new BigNumber('0x1a4406c4ab38715a6f7624ece480aa0e8ca0413514d70506856af0595a853bc3'), new BigNumber('0x2553e174040723a6bf5ea2188d2a1429bb01b13084c4af5b51701e6077716980')]
//     B = [[new BigNumber('0x27c9878700f09edc60cf23d3fb486fe50726f136ff46ad48653a3e7254ae3020'), new BigNumber('0xe35b33188dc2f47618248e4f12a97026c3acdef9b4d021bf94e7b6d9e8ffbb6')], [new BigNumber('0x64cf25d53d57e2931d58d22fe34122fa12def64579c02d0227a496f31678cf8'), new BigNumber('0x26212d004463c9ff80fc65f1f32321333b90de63b6b35805ef24be8b692afb28')]]
//     B_p = [new BigNumber('0x175e0abe73317b738fd5e9fd1d2e3cb48124be9f7ae8080b8dbe419b224e96a6'), new BigNumber('0x85444b7ef6feafa8754bdd3ca0be17d245f13e8cc89c37e7451b55555f6ce9d')]
//     C = [new BigNumber('0x297a60f02d72bacf12a58bae75d4f330bed184854c3171adc6a65bb708466a76'), new BigNumber('0x16b72260e7854535b0a821dd41683a28c89b0d9fcd77d36a157ba709996b490')]
//     C_p = [new BigNumber('0x29ea33c3da75cd937e86aaf6503ec67d18bde775440da90a492966b2eb9081fe'), new BigNumber('0x13fcc4b019b05bc82cd95a6c8dc880d4da92c53abd2ed449bd393e5561d21583')]
//     H = [new BigNumber('0x2693e070bade67fb06a55fe834313f97e3562aa42c46d33c73fccb8f9fd9c2de'), new BigNumber('0x26415689c4f4681680201c1975239c8f454ac4b2217486bc26d92e9dcacb58d7')]
//     K = [new BigNumber('0x11afe3c25ff3821b8b42fde5a85b734cf6000c4b77ec57e08ff5d4386c60c72a'), new BigNumber('0x24174487b1d642e4db86689542b8d6d9e97ec56fcd654051e96e36a8b74ea9ef')]
//
// // Correct input
//     I = [5, 1];

    // console.log("success_count = " + contractInstance.success_count().toLocaleString());
    // console.log("failure_count = " + contractInstance.failure_count().toLocaleString());

// Verify
    contractInstance.verifyTx(A, A_p, B, B_p, C, C_p, H, K, I, params);


    // console.log("after verify");
    // console.log("success_count = " + contractInstance.success_count().toLocaleString());
    // console.log("failure_count = " + contractInstance.failure_count().toLocaleString());

}, 3000);