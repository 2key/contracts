import web3Switcher from "../helpers/web3Switcher";
import getTwoKeyProtocol from "../helpers/twoKeyProtocol";

const {env} = process;

const deployer = web3Switcher.deployer();
const aydnep = web3Switcher.aydnep();
const gmail = web3Switcher.gmail();
const test4 = web3Switcher.test4();
const renata = web3Switcher.renata();
const uport = web3Switcher.uport();
const gmail2 = web3Switcher.gmail2();
const aydnep2 = web3Switcher.aydnep2();
const test = web3Switcher.test();
const buyer = web3Switcher.buyer();
const guest = web3Switcher.guest();

export const userIds = {
  deployer: 'deployer',
  aydnep: 'aydnep',
  gmail: 'gmail',
  test4: 'test4',
  renata: 'renata',
  uport: 'uport',
  gmail2: 'gmail2',
  aydnep2: 'aydnep2',
  test: 'test',
  buyer: 'buyer', // maintainer
  guest: 'guest',
};

const availableUsers = {
  [userIds.deployer]: {
    name: 'DEPLOYER',
    email: 'support@2key.network',
    fullname: 'deployer account',
    walletname: 'DEPLOYER-wallet',
    web3: deployer,
    protocol: getTwoKeyProtocol(deployer.web3, deployer.mnemonic),
    address: env.DEPLOYER_ADDRESS,
  },
  [userIds.aydnep]: {
    name: 'Aydnep',
    email: 'aydnep@gmail.com',
    fullname: 'aydnep account',
    walletname: 'Aydnep-wallet',
    web3: aydnep,
    protocol: getTwoKeyProtocol(aydnep.web3, aydnep.mnemonic),
    address: env.DEPLOYER_ADDRESS,
  },
  [userIds.gmail]: {
    name: 'gmail',
    email: 'aydnep@gmail.com',
    fullname: 'gmail account',
    walletname: 'gmail-wallet',
    web3: gmail,
    protocol: getTwoKeyProtocol(gmail.web3, gmail.mnemonic),
    address: env.GMAIL_ADDRESS,
  },
  [userIds.test4]: {
    name: 'test4',
    email: 'test4@mailinator.com',
    fullname: 'test4 account',
    walletname: 'test4-wallet',
    web3: test4,
    protocol: getTwoKeyProtocol(test4.web3, test4.mnemonic),
    address: env.TEST4_ADDRESS,
  },
  [userIds.renata]: {
    name: 'renata',
    email: 'renata.pindiura@gmail.com',
    fullname: 'renata account',
    walletname: 'renata-wallet',
    web3: renata,
    protocol: getTwoKeyProtocol(renata.web3, renata.mnemonic),
    address: env.RENATA_ADDRESS,
  },
  [userIds.uport]: {
    name: 'uport',
    email: 'aydnep_uport@gmail.com',
    fullname: 'uport account',
    walletname: 'uport-wallet',
    web3: uport,
    protocol: getTwoKeyProtocol(uport.web3, uport.mnemonic),
    address: env.UPORT_ADDRESS,
  },
  [userIds.gmail2]: {
    name: 'gmail2',
    email: 'aydnep+2@gmail.com',
    fullname: 'gmail2 account',
    walletname: 'gmail2-wallet',
    web3: gmail2,
    protocol: getTwoKeyProtocol(gmail2.web3, gmail2.mnemonic),
    address: env.GMAIL2_ADDRESS,
  },
  [userIds.aydnep2]: {
    name: 'aydnep2',
    email: 'aydnep+2@aydnep.com.ua',
    fullname: 'aydnep2 account',
    walletname: 'aydnep2-wallet',
    web3: aydnep2,
    protocol: getTwoKeyProtocol(aydnep2.web3, aydnep2.mnemonic),
    address: env.AYDNEP2_ADDRESS,
  },
  [userIds.test]: {
    name: 'test',
    email: 'test@gmail.com',
    fullname: 'test account',
    walletname: 'test-wallet',
    web3: test,
    protocol: getTwoKeyProtocol(test.web3, test.mnemonic),
    address: env.TEST_ADDRESS,
  },
  [userIds.buyer]: {
    name: 'buyer',
    email: 'buyer@gmail.com',
    fullname: 'buyer account',
    walletname: 'buyer-wallet',
    web3: buyer,
    protocol: getTwoKeyProtocol(buyer.web3, buyer.mnemonic),
    address: env.BUYER_ADDRESS,
  },
  [userIds.guest]: {
    name: 'guest',
    email: 'guest@example.com',
    fullname: 'guest account',
    walletname: 'guest-wallet',
    web3: guest,
    protocol: getTwoKeyProtocol(guest.web3, guest.mnemonic),
    address: undefined,
  }
};

export default availableUsers;
