pragma solidity ^0.4.24;

interface ITwoKeyAdmin {
    function getDefaultIntegratorFeePercent() public view returns (uint);
}

