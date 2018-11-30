export interface ITwoKeyExchangeContract {
    getValue: (from: string) => Promise<number>,
    setValue: (price: number, from: string) => Promise<string>,
}