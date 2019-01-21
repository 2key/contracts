export interface IPlasmaEvents {
    signPlasmaToEthereum: (from: string) => Promise<string>,
    setPlasmaToEthereumOnPlasma: (from: string) => Promise<string | boolean>,
}
