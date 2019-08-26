pragma solidity ^0.4.24;

import "./IERC20.sol";

/**
 * Contract which will represent interface for bancor function
 * 'quickConvert' we're going to use in order to swap tokens
 * through Bancor.
 */
contract IBancorContract {

    /**
     */
    function quickConvert(IERC20[] _path, uint256 _amount, uint256 _minReturn)
    public
    payable
    returns (uint256);
}
