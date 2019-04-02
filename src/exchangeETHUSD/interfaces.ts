import {BigNumber} from "bignumber.js";

export interface ITwoKeyExchangeContract {
    getRatesETHFiat: (currency: string, from: string) => Promise<RateObject>,
    setValue: (currency: string, isGreater: boolean, price: number | string | BigNumber, from: string) => Promise<string>,
}

export interface RateObject {
    rateEth: number,
    isGreater: boolean,
    timeUpdated: number,
    maintainerWhoUpdated: string
}