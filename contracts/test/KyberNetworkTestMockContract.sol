pragma solidity ^0.4.0;
import "../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./FungibleMockToken.sol";

contract KyberNetworkTestMockContract {

    FungibleMockToken public MOCKDAI;

    //We will deploy a MOCK DAI token for this purpose
    constructor() public
    {
        MOCKDAI = new FungibleMockToken("DAI_TOKEN", "DAI", address(this));
    }

    function swapEtherToToken(
        ERC20 token,
        uint minConversionRate
    )
    external
    payable
    returns(uint)
    {
        MOCKDAI.transfer(msg.sender, 1000);
        return 1000;
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
