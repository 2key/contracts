pragma solidity ^0.4.24;

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function onlyMaintainer(address _sender) public view returns (bool);
    //TODO: Delete once hard redeploy is done
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
}
