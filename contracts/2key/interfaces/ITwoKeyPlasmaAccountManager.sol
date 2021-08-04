pragma solidity ^0.4.24;

contract ITwoKeyPlasmaAccountManager {
    function transferUSDFrom(address from, address to, uint amount) external;
    function transfer2KEYFrom(address from, address to, uint amount) external;
    function transfer2KEY(address beneficiary, uint amount) external;
    function get2KEYBalance(address user) external view returns (uint);
    function getUSDBalance(address user) external view returns (uint);
    function withdrawModeratorEarningsUSD() external;
    function withdrawModeratorEarnings2KEY() external;
    function removeBalanceUSD(address beneficiary, uint amount, bytes signature) external;
    function removeBalance2JEY(address beneficiary, uint amount, bytes signature) external;
    function addBalanceUSD(address beneficiary, uint amount, bytes signature) external;
    function addBalance2KEY(address beneficiary, uint amount, bytes signature) external;
}