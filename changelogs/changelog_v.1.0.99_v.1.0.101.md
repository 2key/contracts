### Changelog between v.1.0.99 and v.1.0.101

##### TwoKeyAcquisitionLogicHandler.sol

###### Deleted:
* string public publicMetaHash; // Ipfs hash of json campaign object
* string privateMetaHash; // Ipfs hash of json sensitive (contractor) information
* function updateOrSetIpfsHashPublicMeta(string value) public onlyContractor
* function setPrivateMetaHash(string _privateMetaHash) public onlyContractor
* function getPrivateMetaHash() public view onlyContractor returns (string)


###### Addded:
* function getReferrersBalancesAndTotalEarnings(address[] _referrerPlasmaList) public view returns (uint256[], uint256[])
* function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(address _referrer, bytes signature, uint[] conversionIds) public view returns (uint,uint,uint,uint[])
* function getTotalReferrerEarnings(address _referrer, address eth_address) internal view returns (uint)




##### TwoKeyAcquisitionCampaignERC20.sol

###### Deleted:
* function getReferrersBalancesAndTotalEarnings(address[] _referrerPlasmaList) public view returns (uint256[], uint256[])
* function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(address _referrer, bytes signature, uint[] conversionIds) public view returns (uint,uint,uint,uint[])
* function getTotalReferrerEarnings(address _referrer, address eth_address) internal view returns (uint)

###### Added:
* function getInventoryStatus() public view returns (uint,uint,uint)
* string public publicMetaHash; // Ipfs hash of json campaign object
* string public privateMetaHash; // Ipfs hash of json sensitive (contractor) information
* function updateOrSetPublicMetaHash(string _publicMetaHash) public onlyContractor
* function updateOrSetPrivateMetaHash(string _privateMetaHash) public onlyContractor {


##### 2key-protocol

##### acquisition/index.ts:

* public getInventoryStatus(campaign:any) : Promise<IInventoryStatus> -> Function to return object containing inventory status for campaign
* setPrivateMetaHash -> This function now does both actions of hashing data, uploading to ipfs, and saving the ipfs hash to the contract
* getPrivateMetaHash -> This function now get and decrypt private meta hash

##### acquisition/interfaces.ts
* added interface IInventoryStatus to describe inventory status object
* setPrivateMetaHash: (campaign: any, privateMetaHash: string, from:string) => Promise<string>, -> now accepts data:object instead of privateMetahash:string

##### sign/index.ts
* Change link structure (switch to version 1)
