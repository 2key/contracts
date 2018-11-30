pragma solidity ^0.4.24;


contract ITwoKeyEventSource {
    function created(address _campaign, address _owner, address _moderator) public;
    function converted(address _campaign, address _converter, uint256 _amountETHWei) public;
    function joined(address _campaign, address _from, address _to) public;
    function updatedPublicMetaHash(uint timestamp, string value) public;
    function updatedData(uint timestamp, uint value, string action) public;
    function receivedEther(address _sender, uint _value) public;
}
