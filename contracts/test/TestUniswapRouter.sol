pragma solidity ^0.4.24;

contract TestUniswapRouter {

    function WETH() external pure returns (address) {
        return address(0);
    }

    function getAmountsOut(
        uint amountIn,
        address[] path
    )
    external
    view
    returns (uint[])
    {
        uint [] memory numbers = new uint[](2);
        numbers[0] = 0;
        numbers[1] = (amountIn * (10 ** 18) * 6 / 100) / (10 ** 18);

        return numbers;
    }
}
