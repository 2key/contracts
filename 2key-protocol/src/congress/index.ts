import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {ITwoKeyCongress} from './interfaces';
import {promisify} from '../utils'


export default class TwoKeyCongress implements ITwoKeyCongress {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    public getAllowedMethods(congress:any, from: string) : Promise<string[]> {
        return new Promise(async(resolve,reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let allowedMethods = await promisify(congressInstance.getAllowedMethods, [{from}])
                resolve(allowedMethods);
            } catch (e) {
                reject(e);
            }
        })
    }



}