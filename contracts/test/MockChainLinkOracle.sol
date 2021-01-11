pragma solidity ^0.4.24;

/**
 * MockUniswapOracle contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract MockChainLinkOracle {

    address _oraclesManager;
    int256 _answer;
    uint8 _decimals;
    string _description;
    uint256 _version;

    /**
     * @notice          Function to set initial oracle information
     */
    constructor(
        uint8 decimals_,
        string description_,
        uint256 version_,
        address oraclesManager_
    )
    public
    {
        require(_decimals == 0);
        require(_version == 0);

        _decimals = decimals_;
        _description = description_;
        _version = version_;
        _oraclesManager = oraclesManager_;
    }


    function oraclesManager()
    external
    view
    returns (address)
    {
        return _oraclesManager;
    }


    function decimals()
    external
    view
    returns (uint8)
    {
        return _decimals;
    }


    function description()
    external
    view
    returns (string memory)
    {
        return _description;
    }


    function version()
    external
    view
    returns (uint256)
    {
        return 1;
    }


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
        return (
            0,
            _answer,
            0,
            0,
            0
        );
    }

    function updatePrice(
        int newRateInDecimals
    )
    public
    {
        // Only oracles manager can update price
        require(msg.sender == _oraclesManager);
        _answer = newRateInDecimals;
    }


}
