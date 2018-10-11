pragma solidity ^0.4.24;

import "../2key/TwoKeyTypes.sol";

contract ITwoKeyEventSource is TwoKeyTypes {
    function created(address _campaign, address _owner) public;
    function joined(address _campaign, address _from, address _to) public;
    function escrow(address _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public;
    function rewarded(address _campaign, address _to, uint256 _amount) public;
    function fulfilled(address  _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public;
    function cancelled(address  _campaign, address _converter, string _assetName, address _childContractID, uint256 _indexOrAmount, CampaignType _type) public;
    function updatedPublicMetaHash(uint timestamp, string value) public;
    function updatedData(uint timestamp, uint value, string action) public;
    function receivedEther(address _sender, uint _value) public;
}
