import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyAcquisitionCampaign} from '../interfaces';
import {promisify} from '../utils';
import {ILockup} from './interfaces';

export default class Lockup implements ILockup {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly acquisition: ITwoKeyAcquisitionCampaign;
    // private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, acquisition: ITwoKeyAcquisitionCampaign) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.acquisition = acquisition;
    }

    public getCampaignsWhereConverter(from: string): Promise<string[]> {
        return new Promise<string[]>(async (resolve, reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsConverter, [from]);
                console.log('CONVERTER_CAMPAIGNS', campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        });
    }


}

export { ILockup } from './interfaces';
