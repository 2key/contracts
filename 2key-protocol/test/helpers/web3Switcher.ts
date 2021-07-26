import createWeb3 from "./_web3";
import { rpcUrls, eventsUrls } from "../constants/smallConstants";
const { env } = process;
import {generateMnemonic} from "bip39";


// @ts-ignore
const web3Switcher = {
  deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrls, eventsUrls),
  aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrls, eventsUrls),
  gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrls, eventsUrls),
  test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrls, eventsUrls),
  renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrls, eventsUrls),
  uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrls, eventsUrls),
  gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrls, eventsUrls),
  aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrls, eventsUrls),
  test: () => createWeb3(env.MNEMONIC_TEST, rpcUrls, eventsUrls),
  buyer: () => createWeb3(env.MNEMONIC_BUYER, rpcUrls, eventsUrls),
  guest: () => createWeb3('mnemonic words should be here but for some reason they are missing', rpcUrls, eventsUrls),
  nikola: () => createWeb3(env.MNEMONIC_NIKOLA,rpcUrls, eventsUrls),
  guest_user: () => createWeb3(generateMnemonic(),rpcUrls, eventsUrls)
};

export default web3Switcher;
