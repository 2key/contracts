import {TwoKeyProtocol} from "../../src";
import {generatePlasmaFromMnemonic} from "./_web3";
import {ITwoKeyInit} from "../../src/interfaces";

const { env } = process;

const networkId: number = Number.parseInt(env.MAIN_NET_ID, 10);
const privateNetworkId: number = Number.parseInt(env.SYNC_NET_ID, 10);
const eventsNetUrls: string[] = [env.PLASMA_RPC_URL];

const ipfs = {
    apiUrl: env.IPFS_URL || 'https://ipfs.2key.net/api/v0'
};

export const getTwoKeyProtocolValues = (web3: any, plasmaWeb3: any, plasmaAddress: string): ITwoKeyInit => (
    {
        web3,
        plasmaWeb3,
        plasmaAddress,
        ipfs,
        networkId,
        privateNetworkId,
    }
);


const getTwoKeyProtocol = (web3: any, plasmaWeb3: any, plasmaAddress: string): TwoKeyProtocol =>  {
  return new TwoKeyProtocol(getTwoKeyProtocolValues(web3, plasmaWeb3, plasmaAddress))
};

export default getTwoKeyProtocol;
