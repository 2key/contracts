import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils/promisify'
import {ISignedPlasma, ISignedUser, ISignedWalletData, ITwoKeyReg, IUserData} from "./interfaces";
import Sign from '../sign';

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
    public addName(username:string, sender: string, fullName:string, email:string, signature: string, from: string): Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                 const nonce = await this.helpers._getNonce(from);
                 let txHash = await promisify(this.base.twoKeyReg.addName,[
                        username,
                        sender,
                        fullName,
                        email,
                        signature,
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

    public getRegisteredNameForAddress(from: string): Promise<string> {
        return promisify(this.base.twoKeyReg.address2username, [from]);
    }

    public getRegisteredAddressForName(name: string): Promise<string> {
        return promisify(this.base.twoKeyReg.username2currentAddress, [name]);
    }

    public getRegisteredWalletForAddress(from: string): Promise<string> {
        return promisify(this.base.twoKeyReg.address2walletTag, [from]);
    }

    public getRegisteredAddressForPlasma(plasma: string = this.base.plasmaAddress): Promise<string> {
        return promisify(this.base.twoKeyReg.getPlasmaToEthereum,[plasma]);
    }

    public signUserData2Registry(from: string, name: string, fullname: string, email: string, force?: boolean): Promise<ISignedUser> {
        return new Promise<ISignedUser>(async(resolve, reject) => {
            try {
                let userName;
                let address;
                if (!force) {
                    [userName, address] = await Promise.all([
                        this.getRegisteredNameForAddress(from),
                        this.getRegisteredAddressForName(name),
                    ]);
                    console.log('REGISTRY.storedData', userName, address);
                }
                if (force || (!userName && !parseInt(address, 16))) {
                    const userData = `${name}${fullname}${email}`;
                    const signature = await Sign.sign_name(this.base.web3, from, userData);
                    resolve({
                        name,
                        address: from,
                        fullname,
                        email,
                        signature,
                    });
                } else {
                    reject(new Error(`Already registered, ${userName}:${address}`));
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    public signWalletData2Registry(from: string, username: string, walletname: string, force?: boolean): Promise<ISignedWalletData> {
        return new Promise<ISignedWalletData>(async(resolve, reject) => {
            try {
                let walletTag;
                if (!force) {
                    walletTag = await this.getRegisteredWalletForAddress(from);
                    console.log('walletTag', walletTag);
                }
                if (force || !parseInt(walletTag, 16)) {
                    const userData = `${username}${walletname}`;
                    const signature = await Sign.sign_name(this.base.web3, from, userData);
                    resolve({
                        username,
                        address: from,
                        walletname,
                        signature,
                    });
                } else {
                    reject(new Error('Wallet Already registered!'));
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    public setWalletName(from: string, signedWallet: ISignedWalletData, gasPrice?: number): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
           try {
               const nonce = await this.helpers._getNonce(from);
               const txHash = await promisify(this.base.twoKeyReg.setWalletName, [
                   signedWallet.username, signedWallet.address, signedWallet.walletname, signedWallet.signature, { from, nonce, gasPrice }]);
               resolve(txHash);
           } catch (e) {
               reject(e);
           }
        });
    }

    /**
     * Checks if user is already registered, if not -> proceeds
     * @param {string} from
     * @returns {Promise<ISignedPlasma>}
     */
    public signPlasma2Ethereum(from: string, force?: boolean) : Promise<ISignedPlasma> {
        return new Promise<ISignedPlasma>(async(resolve,reject) => {
            try {
                let plasmaAddress = this.base.plasmaAddress;
                let stored_ethereum_address;
                if (!force) {
                    stored_ethereum_address = await this.getRegisteredAddressForPlasma(plasmaAddress);
                    console.log('REGISTRY.signPlasma2Ethereum', from, stored_ethereum_address);
                }
                let plasmaPrivateKey = "";
                let encryptedPlasmaPrivateKey = "";
                if (force || stored_ethereum_address != from) {
                    plasmaPrivateKey = Sign.add0x(this.base.plasmaPrivateKey);
                    encryptedPlasmaPrivateKey = await Sign.encrypt(this.base.web3, from, plasmaPrivateKey, {});
                    let ethereum2plasmaSignature = await Sign.sign_ethereum2plasma(this.base.plasmaWeb3, from, plasmaAddress);
                    let externalSignature = await Sign.sign_ethereum2plasma_note(this.base.web3,from, ethereum2plasmaSignature,encryptedPlasmaPrivateKey);
                    resolve({
                        encryptedPlasmaPrivateKey,
                        ethereum2plasmaSignature,
                        externalSignature
                    });
                } else {
                    reject(new Error( 'Already registered'));
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
    public addPlasma2EthereumByUser(from: string, signedPlasma: ISignedPlasma, gasPrice?: number) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const { ethereum2plasmaSignature, encryptedPlasmaPrivateKey, externalSignature } = signedPlasma;
                console.log('addPlasma2EthereumByUser\r\n');
                console.log(ethereum2plasmaSignature);
                console.log(encryptedPlasmaPrivateKey);
                console.log(externalSignature);
                let txHash = await promisify(this.base.twoKeyReg.setPlasma2EthereumAndNoteSigned,
                    [ethereum2plasmaSignature,encryptedPlasmaPrivateKey,externalSignature,{from, nonce, gasPrice}]);
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
                let username, fullname, email;
                const hexed = await promisify(this.base.twoKeyReg.getUserData, [address]);
                username = hexed.slice(0,42);
                fullname = hexed.slice(42,42+40);
                email = hexed.slice(42+40,42+40+40);
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

    public addNameAndWalletName(from: string, userName: string, userAddress: string, fullName: string, email: string, walletName: string, signedUserData: string, signedWalletData: string, gasPrice?: number): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const txHash = await promisify(this.base.twoKeyReg.addNameAndSetWalletName, [
                    userName,
                    userAddress,
                    fullName,
                    email,
                    walletName,
                    signedUserData,
                    signedWalletData,
                    { from, nonce, gasPrice }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * Function to delete everything related to user address, only maintainer can call this
     * @param {string} from
     * @param {string} userAddress
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public deleteUser(from: string, username: string, gasPrice ?:number) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                let txHash = await promisify(this.base.twoKeyReg.deleteUser,[username, { from,nonce,gasPrice }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }
}