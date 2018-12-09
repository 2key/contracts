import {BigNumber} from "bignumber.js";

export interface ITwoKeyExchangeContract {
    getValue: (currency: string, from: string) => Promise<any>,
    setValue: (currency: string, isGreater: boolean, price: number | string | BigNumber, from: string) => Promise<string>,
}