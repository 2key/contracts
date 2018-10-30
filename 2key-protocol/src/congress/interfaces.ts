export interface ITwoKeyCongress {
    getAllowedMethods: (congress:any, from: string) => Promise<string[]>,
}
