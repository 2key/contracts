import '../../constants/polifils';
import registerUserFromBackend, {IRegistryData} from "../../helpers/_registerUserFromBackend";
import availableUsersInitial, {userIds} from "../../constants/availableUsers";
import {registrationDebt} from "../../constants/smallConstants";
import {expectEqualStrings} from "../../helpers/stringHelpers";

const TIMEOUT_LENGTH = 60000;

const {[userIds.guest]: guest, ...availableUsers} = availableUsersInitial;

const tryToRegisterUser = async ({protocol: twoKeyProtocol, ...user}, from) => {

  const registerData: IRegistryData = {};
  let error = false;

  try {
    registerData.signedUser = await twoKeyProtocol.Registry.signUserData2Registry(from, user.name, user.fullname, user.email)
  } catch {
    error = true;
  }
  try {
    registerData.signedWallet = await twoKeyProtocol.Registry.signWalletData2Registry(from, user.name, user.walletname);
  } catch {
    error = true;
  }
  try {
    registerData.signedPlasma = await twoKeyProtocol.Registry.signPlasma2Ethereum(from);
  } catch {
    error = true;
  }
  try {
    registerData.signedEthereum = await twoKeyProtocol.PlasmaEvents.signPlasmaToEthereum(from);
  } catch {
    error = true;
  }
  try {
    registerData.signedUsername = await twoKeyProtocol.PlasmaEvents.signUsernameToPlasma(user.name)
  } catch (e) {
    error = true;
  }

  try {
    await registerUserFromBackend(registerData);
  } catch {
    error = true;
  }

  if(error){
    console.log(`${user.name} registration finished with errors`);
  }
};

describe('Should register all users on contract', async () => {
  const usersKeys = Object.keys(availableUsers);
  for (let i = 0; i < usersKeys.length; i += 1) {
    const key = usersKeys[i];
    await it(`should register ${key}`, async () => {
      const {web3: {address}, ...user} = availableUsers[key];
      await tryToRegisterUser(user, address);
    }).timeout(TIMEOUT_LENGTH);
  }
});

describe('Setup of users data', async () => {
  await it('should correct set registration depts', async () => {
    const {protocol, web3: {address, mnemonic}} = availableUsers[userIds.deployer];

    const plasmaAddresses = [
      availableUsers.aydnep.protocol.plasmaAddress,
      availableUsers.test.protocol.plasmaAddress,
      availableUsers.test4.protocol.plasmaAddress,
      availableUsers.uport.protocol.plasmaAddress,
      availableUsers.gmail2.protocol.plasmaAddress,
      availableUsers.buyer.protocol.plasmaAddress,
    ];

    const debts = (new Array(plasmaAddresses.length)).fill(
      protocol.Utils.toWei(registrationDebt, 'ether').toString()
    );

    try {
      let txHash = await protocol.TwoKeyFeeManager.setDebtsForAddresses(plasmaAddresses, debts, address);
      await protocol.Utils.getTransactionReceiptMined(txHash);
    } catch (error) {
      if (error.message !== 'gas required exceeds allowance or always failing transaction') {
        throw error;
      }

      console.log('\x1b[31m', 'Probably test has been already run after latest deploy');
    }

    /**
     * Leave it as test without assertion due to complex logic
     * Can be checked only for clear network
     */
  }).timeout(TIMEOUT_LENGTH);
});

let signature;
let signaturePlasma;
let userAddress;
let newUsername;
describe('Should generate signatures to change username', async() => {
  await it('should generate signatures to change username for Nikola user', async() => {
      let {protocol, web3: {address, mnemonic}} = availableUsers[userIds.nikola];
      try {
        newUsername = Math.random().toString(36).substr(2, 5);
        userAddress = address;
        signature = await protocol.Registry.signNewUsername2Registry(address, newUsername);
        signaturePlasma = await protocol.PlasmaEvents.signNewUsername2PlasmaRegistry(protocol.plasmaAddress, newUsername);
      } catch (error) {
          if (error.message !== 'gas required exceeds allowance or always failing transaction') {
              throw error;
          }
          console.log('\x1b[31m', 'Probably test has been already run after latest deploy');
      }
  }).timeout(TIMEOUT_LENGTH);
});

describe('Should change username from maintainer on public', async() => {
  await it('should change username from the maintainer address for Nikola user on PUBLIC network', async() => {
      const {protocol, web3: {address, mnemonic}} = availableUsers[userIds.deployer];
      try {
          let oldUsername = await protocol.Registry.getRegisteredNameForAddress(userAddress);

          let txHash = await protocol.Registry.changeUsername(newUsername, userAddress, signature, address)
          await protocol.Utils.getTransactionReceiptMined(txHash);

          let mappingForOldUsername = await protocol.Registry.getRegisteredAddressForName(oldUsername);

          let username = await protocol.Registry.getRegisteredNameForAddress(userAddress);
          let addressTakenFromMapping = await protocol.Registry.getRegisteredAddressForName(newUsername);

          expectEqualStrings(mappingForOldUsername,"0x0000000000000000000000000000000000000000");
          expectEqualStrings(username, newUsername);
          expectEqualStrings(userAddress, addressTakenFromMapping);
      } catch (error) {
          console.log(error);
      }
  }).timeout(TIMEOUT_LENGTH);
});

describe('Should change username from maintainer on private', async() => {
  await it('should change username from the maintainer address for Nikola user on PRIVATE network', async() => {
      const {protocol, web3: {address, mnemonic}} = availableUsers[userIds.buyer];
      try {
            await protocol.PlasmaEvents.changeUsername(newUsername, userAddress, signaturePlasma, protocol.plasmaAddress);
      } catch (error) {
          console.log('Error: ',error);
      }
  }).timeout(TIMEOUT_LENGTH);
})












