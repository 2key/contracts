export interface ITwoKeyExchangeContract {
    getValue: (from: string) => Promise<number>,
    setValue: (from: string, price:number) => Promise<string>,
}