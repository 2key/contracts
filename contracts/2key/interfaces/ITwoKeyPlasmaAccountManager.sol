pragma solidity ^0.4.24;

contract ITwoKeyPlasmaAccountManager {
    function transferUSDFrom(address from, address to, uint amount) external;
    function transfer2KEYFrom(address from, address to, uint amount) external;
    function transfer2KEY(address beneficiary, uint amount) external;
    function get2KEYBalance(address user) external view returns (uint);
    function getUSDBalance(address user) external view returns (uint);
}