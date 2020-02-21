pragma solidity ^0.4.24;

contract IUpgradableExchange {

    function buyRate2key() public view returns (uint);
    function sellRate2key() public view returns (uint);

    function buyTokens(
        address _beneficiary
    )
    public
    payable
    returns (uint);

    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    payable;

    function report2KEYWithdrawnFromNetwork(
        uint amountOfTokensWithdrawn
    )
    public;

    function getEth2DaiAverageExchangeRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function getContractId(
        address _contractAddress
    )
    public
    view
    returns (uint);

    function getEth2KeyAverageRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function returnLeftoverAfterRebalancing(
        uint amountOf2key
    )
    public;

    function getMore2KeyTokensForRebalancing(
        uint amountOf2KeyRequested
    )
    public
    view
    returns (uint);

}
