pragma solidity ^0.4.24;

contract ITwoKeyPlasmaAccountManager {
    function transferUSDTFrom(address user, uint amount) external;
    function transfer2KEYFrom(address user, uint amount) external;
    function transfer2KEY(address beneficiary, uint amount) external;
}