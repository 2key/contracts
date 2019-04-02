export interface ISign {
    md5: (text: string, hex?: boolean) => string,
    fixCut: (cut: number | string) => number,
    unfixCut: (cut: number | string) => number,
    add0x: (x: string) => string,
    remove0x: (x: string) => string,
    sign_ethereum2plasma: (plasma_web3: any, my_address: string, plasma_address: string) => Promise<string>,
    sign_referrerWithPlasma: (plasma_web3: any, plasma_address: string, action: string) => Promise<string>,
    sign_plasma2ethereum: (web3: any, plasma_address: string, my_address: string) => Promise<string>,
    sign_ethereum2plasma_note: (web3: any, my_address: string, ethereum2plasma_sig: string, note: string) => Promise<string>,
    decrypt: (web3: any, me: string, encrypted: string, opts: IOptionalParamsSignMessage) => Promise<string>,
    encrypt: (web3: any, address: string, clear_text: string, opts: IOptionalParamsSignMessage) => Promise<string>,
    generatePrivateKey: () => string,
    privateToPublic: (private_key: Buffer) => string,
    // getKey: (web3: any, me: string, opts: IOptionalParamsSignMessage) => Promise<Buffer>,
    // ecsign: (message: string, private_key: Buffer) => string,
    // recoverHash: (hash1: Buffer | Uint8Array, p_message: string) => string,
    // sign_me: (my_address: string, contractAddress: string, i: number, web3: any) => Promise<string>,
    free_take: (my_address: string, f_address: string, f_secret?: string, pMessage?: string) => string,
    free_join: (my_address: string, public_address: string, f_address: string, f_secret: string, p_message: string, rCut: number, cutSign?: string) => string,
    free_join_take: (my_address: string, public_address: string, f_address: string, f_secret: string, p_message: string, cut?: number) => string,
    validate_join: (firstPublicKey: string | null, f_address: string | null, f_secret: string | null, pMessage: string, plasmaAddress: string) => number[],
    sign_cut2eteherum: (userCut: number, my_address: string, web3: any) => Promise<string>,
    generateSignatureKeys: (my_address: string, plasma_address: string, contractAddress: string,  web3: any) => Promise<ISignedKeys>,
    sign_message: (web3, msgParams: IMsgParam[] | string, from, opts?: IOptionalParamsSignMessage) => Promise<string>,
    sign_name: (web3: any, my_address: string, name: string, opts?: IOptionalParamsSignMessage) => Promise<string>,
}

export interface IOptionalParamsSignMessage {
    plasma?: boolean
}

export interface ISignedKeys {
    private_key: string,
    public_address: string,
}

export interface IMsgParam {
    type: string,
    name: string,
    value: string,
}

