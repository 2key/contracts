pragma solidity ^0.4.24;

import "./SafeMath.sol";

/**
 * @notice              Library which will be used to handle price discovery mechanism of 2KEY token
 * @author              Nikola Madjarevic (@madjarevicn)
 */
library PriceDiscovery {

    using SafeMath for uint;

    /**
     * @notice          Function to calculate token price based on amount of tokens in the pool
     *                  currently and initial worth of pool in USD
     *
     * @param           poolInitialAmountInUSD (wei) is the amount how much all tokens in pool should be worth
     * @param           amountOfTokensLeftInPool (wei) is the amount of tokens left in the pool after somebody
     *                  bought them
     * @return          new token price in USD  -> in wei units
     */
    function recalculatePrice(
        uint poolInitialAmountInUSD,
        uint amountOfTokensLeftInPool
    )
    public
    pure
    returns (uint)
    {
        return (poolInitialAmountInUSD.mul(10**18)).div(amountOfTokensLeftInPool);
    }


    function calculateNumberOfIterationsNecessary(
        uint amountOfUSDSpendingForBuyingTokens
    )
    public
    pure
    returns (uint)
    {
        //TBD
    }

    function calculateAmountOfTokensPerIteration(
        uint tokenPrice,
        uint iterationAmount
    )
    public
    pure
    returns (uint)
    {
        return tokenPrice.mul(iterationAmount);
    }
}
