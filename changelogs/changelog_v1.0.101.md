### Changelog after MAJOR breaking changes

Create campaign funnel is now different:

* (+)public create(data: IAcquisitionCampaign, publicMeta:any, privateMeta:any, from: string, {progressCallback, gasPrice, interval, timeout = 60000}: ICreateOpts = {}): Promise<IAcquisitionCampaignMeta>
* (+)IAcquisitionCampaignMeta (expanded) with 2 fields = 
(+)
```
export interface IAcquisitionCampaignMeta {
    contractor: string,
    campaignAddress: string,
    conversionHandlerAddress: string,
    twoKeyAcquisitionLogicHandlerAddress: string,
    campaignPublicLinkKey: string
    ephemeralContractsVersion: string,
    publicMetaHash: string,
    privateMetaHash: string,
}
```
* (+) public addKeysAndMetadataToContract(campaign: any, publicMetaHash: string, privateMetaHash: string, publicLink:string, from: string) : Promise<any>
* (-) getModeratorBalance - deleted
* (+) included ERC20 submodule to handle almost all ERC20 functions
* (+) singletonRegistry/index.ts
* (+) public createProxiesForAcquisitions(addresses: string[],valuesConversion: number[],valuesLogicHandler: any[],valuesCampaign: any[],currency: string,nonSingletonHash: string,from: string) : Promise<any> 
(+)
```
resolve({
'campaignAddress': proxyAcquisition,
'conversionHandlerAddress': proxyConversion,
'twoKeyAcquisitionLogicHandlerAddress': proxyLogic
});
```
* (+) public generateContractorPublicLink(campaign: any, from: string, progressCallback?: any): Promise<any>
* (+) public createPrivateMetaHash(data: any, from:string) : Promise<string>
