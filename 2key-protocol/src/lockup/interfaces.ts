import {BigNumber} from 'bignumber.js';

export interface ILockup {
    withdrawTokens: (twoKeyLockup: string, part: number, from:string) => Promise<string>,
    changeTokenDistributionDate: (twoKeyLockup: string, newDate: number, from: string) => Promise<string>,
    getLockupInformations: (twoKeyLockup: string, from:string) => Promise<LockupInformation>,
}

export interface LockupInformation {
    'baseTokens' : string,
    'bonusTokens' : string,
    'vestingMonths' : number,
    'unlockingDays' : number[],
    'areWithdrawn' : boolean[]
}