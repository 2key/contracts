pragma solidity ^0.4.0;
import "../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract KyberNetworkTestMockContract {
    function swapEtherToToken(
        ERC20 token,
        uint minConversionRate
    )
    external
    payable
    returns(uint)
    {

    }


    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
    external
    view
    returns (uint expectedRate, uint slippageRate)
    {

    }
}
