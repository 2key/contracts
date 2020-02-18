import {TwoKeyProtocol} from "../../src";
import {generatePlasmaFromMnemonic} from "../_web3";
import {ITwoKeyInit} from "../../src/interfaces";

const { env } = process;

const networkId: number = Number.parseInt(env.MAIN_NET_ID, 10);
const privateNetworkId: number = Number.parseInt(env.SYNC_NET_ID, 10);
const eventsNetUrls: string[] = [env.PLASMA_RPC_URL];

export const getTwoKeyProtocolValues = (web3, plasmaMnemonic: string): ITwoKeyInit => (
  {
    web3,
    eventsNetUrls,
    plasmaPK: generatePlasmaFromMnemonic(plasmaMnemonic).privateKey,
    networkId,
    privateNetworkId,
}
);

const getTwoKeyProtocol = (web3, plasmaMnemonic: string): TwoKeyProtocol =>  {
  return new TwoKeyProtocol(getTwoKeyProtocolValues(web3, plasmaMnemonic))
};

export default getTwoKeyProtocol;
