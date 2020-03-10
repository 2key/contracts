import singletons from "../../../src/contracts/singletons";

export default function getTwoKeyEconomyAddress() {
  const networkId = parseInt(process.env.MAIN_NET_ID, 10);

  return singletons.TwoKeyEconomy.networks[networkId].address
}
