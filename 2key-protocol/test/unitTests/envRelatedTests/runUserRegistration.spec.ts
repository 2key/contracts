import '../../constants/polifils';
import registerUserFromBackend, {IRegistryData} from "../../helpers/_registerUserFromBackend";
import availableUsersInitial from "../../constants/availableUsers";
import {generatePlasmaFromMnemonic} from "../../helpers/_web3";
import {registrationDebt} from "../../constants/smallConstants";

const TIMEOUT_LENGTH = 60000;

const {guest, ...availableUsers} = availableUsersInitial;

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
  } catch {
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
      const {web3: {address, mnemonic}, ...user} = availableUsers[key];
      await tryToRegisterUser(user, address);
    }).timeout(TIMEOUT_LENGTH);
  }
});

describe('Setup of users data', async () => {
  await it('should correct set registration depts', async () => {
    const {protocol, web3: {address}} = availableUsers.deployer;

    // TODO: Relates to user registration
    const plasmaAddresses = [
      generatePlasmaFromMnemonic(availableUsers.test.web3.mnemonic).address,
      generatePlasmaFromMnemonic(availableUsers.test4.web3.mnemonic).address,
      generatePlasmaFromMnemonic(availableUsers.uport.web3.mnemonic).address,
      generatePlasmaFromMnemonic(availableUsers.gmail2.web3.mnemonic).address,
      generatePlasmaFromMnemonic(availableUsers.buyer.web3.mnemonic).address,
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
    let stats = await protocol.TwoKeyFeeManager.getDebtsSummary();
    console.log({stats});
  }).timeout(TIMEOUT_LENGTH);
});
