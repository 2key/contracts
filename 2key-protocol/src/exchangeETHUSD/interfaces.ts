export interface ITwoKeyExchangeContract {
    getValue: (currency: string, from: string) => Promise<number>,
    setValue: (currency: string, price: number, from: string) => Promise<string>,
}