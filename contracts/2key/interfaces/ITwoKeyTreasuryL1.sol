pragma solidity ^0.4.24;

/**
 * ITwoKeyTreasuryL1 contract.
 * @author David Lee
 * Github: 0xKey
 */

contract ITwoKeyTreasuryL1 {
    function recoverSignature(address userAddress, uint amountOfTokens, bytes signature) public view returns (address);
    function depositToken(address token, uint amount) public;
    function withdrawTokens(address beneficiary, uint amount, bytes signature) public;
    function getBalanceOf(address token) public view returns (uint);
}
