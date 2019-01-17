export interface IPlasmaEvents {
    setPlasmaToEthereumOnPlasma: (from: string) => Promise<string>,
    signPlasmaToEthereum: (from: string) => Promise<string>,
}
