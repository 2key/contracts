pragma solidity ^0.4.24;

/**
 * IChainlinkOracle contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract IChainlinkOracle {
    function getLatestPrice() public view returns (int);
}
