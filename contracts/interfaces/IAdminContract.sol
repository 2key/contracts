pragma solidity ^0.4.24;

interface IAdminContract {
    function replaceOneself(address newAdminContract) external;
    function transferByAdmins(address to, uint256 tokens) external;
    function upgradeEconomyExchangeByAdmins(address newExchange) external;
    function transferEtherByAdmins(address to, uint256 amount) external;
}

