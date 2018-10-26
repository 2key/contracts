export interface IERC20 {
    getERC20Symbol: (erc20: any) => Promise<string>,
    erc20ApproveAddress: (erc20:any, address:string, spenderAddress: string, value:number, from: string) => Promise<string>,
}

