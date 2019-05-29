pragma solidity ^0.4.0;

contract ITwoKeyMaintainersRegistry {
    function onlyMaintainer(address _sender) public view returns (bool);
}
