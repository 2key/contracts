export interface IPlasmaEvents {
    signPlasmaToEthereum: (from: string) => Promise<string>,
    setPlasmaToEthereumOnPlasma: (plasmaAddress: string, plasma2EthereumSignature: string) => Promise<string>,
}
