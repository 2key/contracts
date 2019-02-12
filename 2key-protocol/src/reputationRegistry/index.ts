import {IReputationStatsPerAddress, ITwoKeyBaseReputationRegistry} from "./interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from '../utils/promisify';

export default class TwoKeyBaseReputationRegistry implements ITwoKeyBaseReputationRegistry {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    /**
     *
     * @param {ITwoKeyBase} twoKeyProtocol
     * @param {ITwoKeyHelpers} helpers
     * @param {ITwoKeyUtils} utils
     */
    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }


    /**
     * Returns reputation points for one address per role
     * @param {string} address
     * @returns {Promise<IReputationStatsPerAddress>}
     */
    public getReputationPointsForAllRolesPerAddress(address: string) : Promise<IReputationStatsPerAddress> {
        return new Promise<IReputationStatsPerAddress>(async(resolve,reject) => {
            try {
                let stats = await promisify(this.base.twoKeyBaseReputationRegistry.getRewardsByAddress,[address]);
                let contractorPoints = parseInt(stats.slice(0,66),16);
                let isPositive = parseInt(stats.slice(66,66+2),16) == 1 ? true : false;
                if(!isPositive) {
                    contractorPoints = contractorPoints*(-1);
                }
                let converterPoints = parseInt(stats.slice(66+2, 66+2+64),16);
                isPositive = parseInt(stats.slice(66+2+64,66+2+64+2),16) == 1 ? true : false;
                if(!isPositive) {
                    converterPoints = converterPoints * (-1);
                }

                let referrerPoints = parseInt(stats.slice(66+2+64+2, 66+2+64+2+64),16);
                isPositive = parseInt(stats.slice(66+2+64+2+64,66+2+64+2+64+2),16) == 1 ? true : false;
                if(!isPositive) {
                    referrerPoints = referrerPoints * (-1);
                }

                let obj: IReputationStatsPerAddress = {
                    reputationPointsAsContractor : contractorPoints,
                    reputationPointsAsConverter : converterPoints,
                    reputationPointsAsReferrer : referrerPoints
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }
}