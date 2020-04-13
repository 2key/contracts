require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
import registerUserFromBackend, {IRegistryData} from "./_registerUserFromBackend";
import {TwoKeyProtocol} from '../src';
import web3Switcher from "./helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "./helpers/twoKeyProtocol";

let twoKeyProtocol: TwoKeyProtocol;
const TIMEOUT_LENGTH = 60000;

const users = {
  'deployer': {
    name: 'DEPLOYER',
    email: 'support@2key.network',
    fullname: 'deployer account',
    walletname: 'DEPLOYER-wallet',
    web3: web3Switcher.deployer(),
  },
  'aydnep': {
    name: 'Aydnep',
    email: 'aydnep@gmail.com',
    fullname: 'aydnep account',
    walletname: 'Aydnep-wallet',
    web3: web3Switcher.aydnep(),
  },
  'gmail': {
    name: 'gmail',
    email: 'aydnep@gmail.com',
    fullname: 'gmail account',
    walletname: 'gmail-wallet',
    web3: web3Switcher.gmail(),
  },
  'test4': {
    name: 'test4',
    email: 'test4@mailinator.com',
    fullname: 'test4 account',
    walletname: 'test4-wallet',
    web3: web3Switcher.test4(),
  },
  'renata': {
    name: 'renata',
    email: 'renata.pindiura@gmail.com',
    fullname: 'renata account',
    walletname: 'renata-wallet',
    web3: web3Switcher.renata(),
  },
  'uport': {
    name: 'uport',
    email: 'aydnep_uport@gmail.com',
    fullname: 'uport account',
    walletname: 'uport-wallet',
    web3: web3Switcher.uport(),
  },
  'gmail2': {
    name: 'gmail2',
    email: 'aydnep+2@gmail.com',
    fullname: 'gmail2 account',
    walletname: 'gmail2-wallet',
    web3: web3Switcher.gmail2(),
  },
  'aydnep2': {
    name: 'aydnep2',
    email: 'aydnep+2@aydnep.com.ua',
    fullname: 'aydnep2 account',
    walletname: 'aydnep2-wallet',
    web3: web3Switcher.aydnep2(),
  },
  'test': {
    name: 'test',
    email: 'test@gmail.com',
    fullname: 'test account',
    walletname: 'test-wallet',
    web3: web3Switcher.test(),
  },
  'buyer': {
    name: 'buyer',
    email: 'buyer@gmail.com',
    fullname: 'buyer account',
    walletname: 'buyer-wallet',
    web3: web3Switcher.buyer(),
  }
};


const tryToRegisterUser = async (user, from) => {
  console.log('REGISTERING', user.name);
  const registerData: IRegistryData = {};
  try {
    registerData.signedUser = await twoKeyProtocol.Registry.signUserData2Registry(from, user.name, user.fullname, user.email)
  } catch {
    console.log('Error in Registry.signUserData');
  }
  try {
    registerData.signedWallet = await twoKeyProtocol.Registry.signWalletData2Registry(from, user.name, user.walletname);
  } catch {
    console.log('Error in Registry.singWalletData');
  }
  try {
    registerData.signedPlasma = await twoKeyProtocol.Registry.signPlasma2Ethereum(from);
  } catch {
    console.log('Error Registry.signPlasma');
  }
  try {
    registerData.signedEthereum = await twoKeyProtocol.PlasmaEvents.signPlasmaToEthereum(from);
  } catch (e) {
    console.log('Error Plasma.signEthereum');
    console.log(e);
  }
  try {
    registerData.signedUsername = await twoKeyProtocol.PlasmaEvents.signUsernameToPlasma(user.name)
  } catch (e) {
    console.log('Error Plasma.signedUsername');
    console.log(e);
  }
  let registerReceipts;
  try {
    registerReceipts = await registerUserFromBackend(registerData);
  } catch (e) {
    console.log(e);
  }

  return registerReceipts;
};


describe('Should register all users on contract', () => {
  const usersKeys = Object.keys(users);
  for (let i = 0; i < usersKeys.length; i += 1) {
    const key = usersKeys[i];
    it(`should register ${key}`, async () => {
      const {web3: {web3, address, mnemonic}, ...user} = users[key];
      twoKeyProtocol = getTwoKeyProtocol(web3, mnemonic);

      await tryToRegisterUser(user, address);
    }).timeout(TIMEOUT_LENGTH);
  }
});
