pragma solidity ^0.4.24;

import "./FungibleMockToken.sol";

contract KyberNetworkTestMockContract {

    constructor() public
    {
    }

    function swapEtherToToken(
        ERC20 token,
        uint minConversionRate
    )
    public
    payable
    returns(uint)
    {
        return 1000*(10**18);
    }


    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
    public
    view
    returns (uint expectedRate, uint slippageRate)
    {
        expectedRate = 1000;
        slippageRate = 1;
    }


    function getBalanceOfEtherOnContract()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }
}
