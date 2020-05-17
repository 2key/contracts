pragma solidity ^0.4.24;
import "../ERC20/ERC20.sol";

/**
 * @notice Interface which will be used for 2KEY system to interact with Kyber smart-contracts
 */
contract IKyberReserveInterface {

    /**
     * @notice          Function to be called on contract LiquidityConversionRates.sol
     *                  Can be only called by TwoKeyAdmin when we're initially setting
     *                  up the reserve
     */
    function setLiquidityParams(
        uint _rInFp,
        uint _pMinInFp,
        uint _numFpBits,
        uint _maxCapBuyInWei,
        uint _maxCapSellInWei,
        uint _feeInBps,
        uint _maxTokenToEthRateInPrecision,
        uint _minTokenToEthRateInPrecision
    ) public;

    function withdraw(ERC20 token, uint amount, address destination) public returns(bool);
    function disableTrade() public returns (bool);
    function enableTrade() public returns (bool);
    function withdrawEther(uint amount, address sendTo) external;
    function withdrawToken(ERC20 token, uint amount, address sendTo) external;
    function getDestQty(ERC20 src, ERC20 dest, uint srcQty, uint rate) public view returns(uint);
}
