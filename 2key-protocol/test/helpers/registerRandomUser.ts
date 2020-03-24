import createWeb3 from "./_web3";
import {registrationDebt, rpcUrls} from "../constants/smallConstants";
import getTwoKeyProtocol from "./twoKeyProtocol";
import registerUserFromBackend, {IRegistryData} from "./_registerUserFromBackend";
import availableUsers, {userIds} from "../constants/availableUsers";

let counter = 1;

export function getUniqueId() {
  counter += 1;
  return `random-${(new Date()).getTime()}-${counter}`
}

export default async function registerRandomUser(
  id: string,
  tokensAmount: number = 0,
  etherAmount: number = 10,
) {
  const {protocol: protocolAydnep, web3: web3Aydnep} = availableUsers[userIds.aydnep];
  const {protocol: protocolDeployer, web3: web3Deployer} = availableUsers[userIds.deployer];

  const web3 = createWeb3('', rpcUrls);
  const protocol = getTwoKeyProtocol(web3.web3, web3.mnemonic);
  const deptWei = Number.parseInt(protocol.Utils.toWei(registrationDebt, 'ether').toString(), 10);
  const user = {
    name: id,
    email: `${id}@2key.network`,
    fullname: `${id} account`,
    walletname: `${id}-wallet`,
    web3,
    protocol,
  };
  const registerData: IRegistryData = {};

  registerData.signedUser = await protocol.Registry.signUserData2Registry(
    web3.address, user.name, user.fullname, user.email,
  );
  registerData.signedWallet = await protocol.Registry.signWalletData2Registry(web3.address, user.name, user.walletname);
  registerData.signedPlasma = await protocol.Registry.signPlasma2Ethereum(web3.address);
  registerData.signedEthereum = await protocol.PlasmaEvents.signPlasmaToEthereum(web3.address);
  registerData.signedUsername = await protocol.PlasmaEvents.signUsernameToPlasma(user.name);

  await registerUserFromBackend(registerData);

  await protocol.Utils.getTransactionReceiptMined(
    await protocolDeployer.TwoKeyFeeManager.setDebtsForAddresses(
      [protocol.plasmaAddress], [deptWei], web3Deployer.address
    )
  );

  if (tokensAmount > 0) {
    await protocolAydnep.Utils.getTransactionReceiptMined(
      await protocolAydnep.transfer2KEYTokens(
        web3.address,
        protocolAydnep.Utils.toWei(tokensAmount, 'ether'),
        web3Aydnep.address,
      )
    );
  }

  if (etherAmount > 0) {
    await protocolDeployer.Utils.getTransactionReceiptMined(
      await protocolDeployer.transferEther(
        web3.address,
        protocolAydnep.Utils.toWei(etherAmount, 'ether'),
        web3Deployer.address,
      )
    );
  }

  return user;
}
