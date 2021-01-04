pragma solidity ^0.4.24;

/**
 * MockUniswapOracle contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract MockUniswapOracle {

    string public oracleName;
    int rate;

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    )
    {
        roundId = 0;
        answer = rate;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }

    function setRate(int _rate)
    public
    {
        rate = _rate;
    }
}
