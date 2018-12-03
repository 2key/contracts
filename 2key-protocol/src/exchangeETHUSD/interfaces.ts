export interface ITwoKeyExchangeContract {
    getValue: (currency: string, from: string) => Promise<any>,
    setValue: (currency: string, isGreater: boolean, price: number, from: string) => Promise<string>,
}