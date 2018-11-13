export interface ITwoKeyReg {
    checkIfUserIsRegistered: (address: string, from: string) => Promise<boolean>,

}