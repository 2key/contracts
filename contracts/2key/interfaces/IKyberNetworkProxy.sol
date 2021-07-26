pragma solidity ^0.4.24;
import "../ERC20/ERC20.sol";


contract IKyberNetworkProxy {
    function swapEtherToToken(
        ERC20 token,
        uint minConversionRate
    )
    public
    payable
    returns(uint);

    function swapTokenToToken(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        uint minConversionRate
    )
    public
    returns (uint);

    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
    public
    view
    returns (uint expectedRate, uint slippageRate);
}
