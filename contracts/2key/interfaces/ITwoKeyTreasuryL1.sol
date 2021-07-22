pragma solidity ^0.4.24;

/**
 * ITwoKeyTreasuryL1 contract.
 * @author David Lee
 * Github: 0xKey
 */

contract ITwoKeyTreasuryL1 {
    function setTokenAddress(string tokenName, address tokenAddress) external;
    function getTokenAddress(string tokenName) external view;
    function recoverSignature(address userAddress, uint amountOfTokens, bytes signature) external view returns (address);
    function deposit2KEY(address token, uint amount) external;
    function depositStableCoin(address token, uint amount) external;
    function depositVolatileToken(address token, uint amount) external;
    function withdrawModeratorEarnings(address beneficiary, uint amount, uint buy2keyRateL2, bytes signature, bool is2KEYWithdraw) external;
    function withdrawToken(uint amount, uint buy2keyRateL2, bytes signature, bool is2KEYWithdraw) external;
    function getBalanceOf(address token) external view returns (uint);
}
