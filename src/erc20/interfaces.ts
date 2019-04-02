export interface IERC20 {
    getERC20Symbol: (erc20: any) => Promise<string>,
    erc20ApproveAddress: (erc20:any, address:string, spenderAddress: string, value:number, from: string) => Promise<string>,
    getERC20Balance: (erc20: any, address: string) => Promise<number>,
    getTokenName: (erc20: any) => Promise<string>,
    getTokenDecimals: (erc20: any) => Promise<number>,
    transferFrom: (erc20: any, tokens_from: string, to: string, value:string, from:string) => Promise<string>,
    transfer: (erc20:any, to:string, value:string, from:string) => Promise<string>,
    getTotalSupply: (erc20: any) => Promise<number>
}

