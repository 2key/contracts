import registerUserFromBackend, {IRegistryData} from "./_registerUserFromBackend";
import {TwoKeyProtocol} from '../src';
import web3Switcher from "./helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "./helpers/twoKeyProtocol";
let twoKeyProtocol: TwoKeyProtocol;
const TIMEOUT_LENGTH = 60000;
const {env} = process;

let from: string;

const users = {
    'deployer': {
        name: 'DEPLOYER',
        email: 'support@2key.network',
        fullname:  'deployer account',
        walletname: 'DEPLOYER-wallet',
    },
    'aydnep': {
        name: 'Aydnep',
        email: 'aydnep@gmail.com',
        fullname:  'aydnep account',
        walletname: 'Aydnep-wallet',
    },
    'nikola': {
        name: 'Nikola',
        email: 'nikola@2key.co',
        fullname: 'Nikola Madjarevic',
        walletname: 'Nikola-wallet',
    },
    'andrii': {
        name: 'Andrii',
        email: 'andrii@2key.co',
        fullname: 'Andrii Pindiura',
        walletname: 'Andrii-wallet',

    },
    'Kiki': {
        name: 'Kiki',
        email: 'kiki@2key.co',
        fullname: 'Erez Ben Kiki',
        walletname: 'Kiki-wallet',
    },
    'gmail': {
        name: 'gmail',
        email: 'aydnep@gmail.com',
        fullname: 'gmail account',
        walletname: 'gmail-wallet',
    },
    'test4': {
        name: 'test4',
        email: 'test4@mailinator.com',
        fullname: 'test4 account',
        walletname: 'test4-wallet',
    },
    'renata': {
        name: 'renata',
        email: 'renata.pindiura@gmail.com',
        fullname: 'renata account',
        walletname: 'renata-wallet',
    },
    'uport': {
        name: 'uport',
        email: 'aydnep_uport@gmail.com',
        fullname: 'uport account',
        walletname: 'uport-wallet',
    },
    'gmail2': {
        name: 'gmail2',
        email: 'aydnep+2@gmail.com',
        fullname: 'gmail2 account',
        walletname: 'gmail2-wallet',
    },
    'aydnep2': {
        name: 'aydnep2',
        email: 'aydnep+2@aydnep.com.ua',
        fullname: 'aydnep2 account',
        walletname: 'aydnep2-wallet',
    },
    'test': {
        name: 'test',
        email: 'test@gmail.com',
        fullname: 'test account',
        walletname: 'test-wallet',
    },
    'buyer': {
        name: 'buyer',
        email: 'buyer@gmail.com',
        fullname: 'buyer account',
        walletname: 'buyer-wallet',
    }
};


const tryToRegisterUser = async (username, from) => {
    console.log('REGISTERING', username);
    const user = users[username.toLowerCase()];
    const registerData: IRegistryData = {};
    try  {
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
    it('should register deployer', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);

        await tryToRegisterUser('Deployer', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register aydnep', async() => {
        const {web3, address} = web3Switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_AYDNEP));

        await tryToRegisterUser('Aydnep', from);
    }).timeout(TIMEOUT_LENGTH);

    it('should register gmail', async() => {
        const {web3, address} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_GMAIL));

        await tryToRegisterUser('gmail', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register test4', async() => {
        const {web3, address} = web3Switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST4));

        await tryToRegisterUser('test4', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register renata', async() => {
        const {web3, address} = web3Switcher.renata();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_RENATA));

        await tryToRegisterUser('renata', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register renata', async() => {
        const {web3, address} = web3Switcher.uport();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_UPORT));

        await tryToRegisterUser('uport', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register gmail2', async() => {
        const {web3, address} = web3Switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_GMAIL2));

        await tryToRegisterUser('gmail2', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register aydnep2', async() => {
        const {web3, address} = web3Switcher.aydnep2();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_AYDNEP2));

        await tryToRegisterUser('aydnep2', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register test', async() => {
        const {web3, address} = web3Switcher.aydnep2();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST));

        await tryToRegisterUser('test', from);
    }).timeout(TIMEOUT_LENGTH);


    it('should register guest', async() => {
        const {web3, address} = web3Switcher.guest();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, 'mnemonic words should be here but for some reason they are missing'));

        await tryToRegisterUser('guest', from);
    }).timeout(TIMEOUT_LENGTH);

    it('should register buyer', async() => {
        const {web3, address} = web3Switcher.buyer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_BUYER));

        await tryToRegisterUser('buyer', from);
    }).timeout(TIMEOUT_LENGTH);

});
