### Changelog

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


