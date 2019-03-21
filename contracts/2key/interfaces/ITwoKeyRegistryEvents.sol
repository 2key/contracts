pragma solidity ^0.4.0;

contract ITwoKeyRegistryEvents {
    mapping(address => bool) public isMaintainer;

    function addWhereContractor(address _userAddress, address _contractAddress) public;
    function addWhereModerator(address _userAddress, address _contractAddress) public;
    function addWhereReferrer(address _userAddress, address _contractAddress) public;
    function addWhereConverter(address _userAddress, address _contractAddress) public;
    function getPlasmaToEthereum(address plasma) public view returns (address);
    function getEthereumToPlasma(address ethereum) public view returns (address);
}
