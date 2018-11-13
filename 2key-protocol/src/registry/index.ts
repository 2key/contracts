import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils'
import {ITwoKeyReg} from "./interfaces";

export default class ERC20 implements ITwoKeyReg {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
    }

    public checkIfUserIsRegistered(address: string, from: string) : Promise<boolean> {
        return new Promise(async(resolve,reject) => {
            try {
                const registryInstance = await this.helpers._getTwoKeyCongressInstance(this.base.twoKeyReg);
                let isRegistered = await promisify(registryInstance.checkIfUserExists,[address, {from}]);
                resolve(isRegistered);
            } catch (e) {
                reject(e);
            }
        })
    }




}