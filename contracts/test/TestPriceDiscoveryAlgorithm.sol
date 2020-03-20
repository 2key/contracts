pragma solidity ^0.4.24;

import "../2key/libraries/PriceDiscovery.sol";

contract TestPriceDiscoveryAlgorithm {

    using SafeMath for *;

    uint constant public WEI = 10**18;

    // 18 MILION TOKENS in WEI
    uint public POOL_SUPPLY = WEI.mul(18000000);

    // 1.08 MIL DOLLARS
    uint public POOL_VALUE = WEI.mul(1080000);

    // Token price is 6 cents in WEI
    uint public TOKEN_PRICE = WEI.mul(6).div(100);

    constructor() {

    }

    function testPriceRecalculation(
        uint amountOfTokensLeftInPool
    )
    public
    view
    returns (uint)
    {
        return PriceDiscovery.recalculatePrice(POOL_VALUE, amountOfTokensLeftInPool);
    }

    function testNumberOfIterations(
        uint amountOfUSDSpending
    )
    public
    view
    returns (uint,uint)
    {
        return PriceDiscovery.calculateNumberOfIterationsNecessary(
            amountOfUSDSpending.mul(10**18),
            TOKEN_PRICE,
            POOL_SUPPLY
        );
    }

    function testCalculatePercentageOfThePoolWei(
        uint amountSpendingToBuyTokens
    )
    public
    view
    returns (uint,uint)
    {
        return PriceDiscovery.calculatePercentageOfThePoolWei(
            amountSpendingToBuyTokens.mul(10**18),
            POOL_SUPPLY,
            TOKEN_PRICE
        );
    }

    function testCalculateTotalTokensUserIsGetting(
        uint amountOfUSDSpending
    )
    public
    view
    returns (uint,uint)
    {
        return PriceDiscovery.calculateTotalTokensUserIsGetting(
            amountOfUSDSpending.mul(10**18),
            TOKEN_PRICE,
            POOL_SUPPLY,
            POOL_VALUE
        );
    }

    function testCalculateAmountOfTokensPerIterationAndNewPrice(
        uint iterationAomunt
    )
    public
    view
    returns (uint,uint,uint)
    {
        return PriceDiscovery.calculateAmountOfTokensPerIterationAndNewPrice(
            POOL_SUPPLY,
            TOKEN_PRICE,
            iterationAomunt,
            POOL_VALUE
        );
    }



}
