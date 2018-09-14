function promisify(func: any, args: any): Promise<any> {
    return new Promise((res, rej) => {
        func(...args, (err: any, data: any) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}

function isContractDeployed(web3: any, address: string): Promise<boolean> {
    return new Promise(async (resolve, reject) => {
        const code = await promisify(web3.eth.getCode, [address]);
        if (code.length < 4) {
            reject(new Error(`Contract at ${address} doesn't exist!`));
        } else {
            resolve(true);
        }
    });
}

class Contract {
    private web3: any;
    public static createAndValidate(web3: any, abi: any, address: string) {
        return new Promise(async (resolve, reject) => {
            try {
                if (await isContractDeployed(web3, address)) {
                    resolve(web3.eth.contract(abi).at(address));
                }
            } catch (err) {
                reject(err);
            }
        });
    }


}
