pragma solidity ^0.4.24;

contract ITwoKeyPlasmaAccountManager {
    function transferUSDTFrom(address from, address to, uint amount) external;
    function transfer2KEYFrom(address from, address to, uint amount) external;
    function transfer2KEY(address beneficiary, uint amount) external;
}