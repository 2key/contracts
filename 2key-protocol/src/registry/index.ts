import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils'
import {ISignedPlasma, ITwoKeyReg, IUserData} from "./interfaces";
import Sign from '../utils/sign';
import {strict} from "assert";

export default class TwoKeyReg implements ITwoKeyReg {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

        /**
     *
     * @param {string} username
     * @param {string} address
     * @param {string} fullName
     * @param {string} email
     * @param {string} from
     * @returns {Promise<string>}
     */
    public addName(username:string, address:string, fullName:string, email:string, from: string): Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                 const nonce = await this.helpers._getNonce(from);
                 let txHash = await promisify(this.base.twoKeyReg.addName,[
                        username,
                        address,
                        fullName,
                        email,
                        {
                            from,
                            nonce
                        }
                    ]);
                    await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch(e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param {string} address
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public checkIfAddressIsRegistered(address: string) : Promise<boolean> {
        return new Promise(async(resolve,reject) => {
            try {
                let isRegistered = await promisify(this.base.twoKeyReg.checkIfUserExists,[address]);
                resolve(isRegistered);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param {string} address
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public checkIfUserIsRegistered(username: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const handle = this.base.web3.sha3(username);
                let isRegistered = await promisify(this.base.twoKeyReg.username2currentAddress,[handle]);
                resolve(isRegistered);
            } catch (e) {
                reject(e);
            }
        });
    }

    public signUsername(username: string, from:string): Promise<string> {
        return Sign.sign_name(this.base.web3,from,username);
    }

    /**
     *
     * @param {string} username
     * @param {string} from
     * @returns {Promise<string>}c
     */
    public addNameSignedToRegistry(username: string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let externalSig = await this.signUsername(from, username);
                console.log(username,externalSig);
                let txHash = await promisify(this.base.twoKeyReg.addNameSigned,[username, externalSig, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getPlasmaPrivateKeyFromNotes(from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let notes = await this.getNotes(from);
                let decrypted = await Sign.decrypt(this.base.web3, from, notes, {});
                let privateKey = Sign.remove0x(decrypted);
                resolve(privateKey);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getNotes(from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let notes = await promisify(this.base.twoKeyReg.notes,[from]);
                resolve(notes);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} note
     * @param {string} from
     * @returns {Promise<string>}
     */
    public setNoteByUser(note: string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let txHash = await promisify(this.base.twoKeyReg.setNoteByUser,[note,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Checks if user is already registered, if not -> proceeds
     * @param {string} from
     * @returns {Promise<ISignedPlasma>}
     */
    public signPlasma2Ethereum(from: string) : Promise<ISignedPlasma | boolean> {
        return new Promise<ISignedPlasma | boolean>(async(resolve,reject) => {
            try {
                console.log('REGISTRY.signPlasma2Ethereum', from);
                let plasmaAddress = this.base.plasmaAddress;
                let stored_ethereum_address = await promisify(this.base.twoKeyReg.getPlasmaToEthereum,[plasmaAddress]);
                let plasmaPrivateKey = "";
                let encryptedPlasmaPrivateKey = "";
                console.log('Beofre if',plasmaAddress,stored_ethereum_address,from);
                if(stored_ethereum_address != from) {
                    plasmaPrivateKey = Sign.add0x(this.base.plasmaPrivateKey);
                    encryptedPlasmaPrivateKey = await Sign.encrypt(this.base.web3, from, plasmaPrivateKey, {});
                    console.log('encryptedPlasmaPrivateKey', encryptedPlasmaPrivateKey);
                    let ethereum2plasmaSignature = await Sign.sign_ethereum2plasma(this.base.plasmaWeb3, from, this.base.plasmaAddress);
                    let externalSignature = await Sign.sign_ethereum2plasma_note(this.base.web3,from, ethereum2plasmaSignature,encryptedPlasmaPrivateKey);
                    resolve({
                        encryptedPlasmaPrivateKey,
                        ethereum2plasmaSignature,
                        externalSignature
                    });
                } else {
                    resolve(false);
                }

            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string>}
     */
    public addPlasma2EthereumByUser(from: string, signedPlasma: ISignedPlasma) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const {encryptedPlasmaPrivateKey, ethereum2plasmaSignature, externalSignature} = signedPlasma;
                let txHash = await promisify(this.base.twoKeyReg.setPlasma2EthereumAndNoteSigned,
                    [ethereum2plasmaSignature,encryptedPlasmaPrivateKey,externalSignature,{from}]);
                resolve(txHash);

            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} address
     * @returns {Promise<IUserData>}
     */
    public getUserData(address: string) : Promise<IUserData> {
        return new Promise(async(resolve,reject) => {
            try {
                const [username, fullname, email] = await promisify(this.base.twoKeyReg.getUserData, [address]);
                resolve({
                    username,
                    fullname,
                    email,
                });
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsConverter(address: string): Promise<string[]> {
        return new Promise<string[]>(async (resolve, reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsConverter, [address]);
                console.log('Campaigns where' + address + 'is converter: ', campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsContractor(address: string) : Promise<string[]> {
        return new Promise<string[]>(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsContractor,[address]);
                console.log('Campaigns where : ' + address + 'is contractor: ' +  campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsModerator(address: string) : Promise<string[]> {
        return new Promise(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsModerator,[address]);
                console.log('Campaigns where : ' + address + 'is moderator: ' + campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsReferrer(address: string) : Promise<string[]> {
        return new Promise(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsReferrer,[address]);
                console.log('Campaigns where: '+ address + 'is referrer: ' + campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param {string} username
     * @param {string} address
     * @param {string} username_walletName
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public setWalletName(username: string, address: string, username_walletName: string, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const txHash = await promisify(this.base.twoKeyReg.setWalletName,
                    [
                        username,
                        address,
                        username_walletName,
                        {
                            from,
                            gasPrice,
                            nonce
                        }
                    ]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }



}