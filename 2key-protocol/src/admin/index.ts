import {ITwoKeyUtils} from "../utils/interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {promisify} from '../utils/promisify';
import {ITwoKeyAdmin} from "./interfaces";


export default class TwoKeyAdmin implements ITwoKeyAdmin {

    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    /**
     * Gets integrator fee from twokeyadmin contract
     * @returns {Promise<number>}
     */
    public getIntegratorFeePercentage() : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                let integratorFee = await promisify(this.base.twoKeyAdmin.getDefaultIntegratorFeePercent,[]);
                resolve(integratorFee);
            } catch (e) {
                reject(e);
            }
        })
    }

}