pragma solidity ^0.4.24;

// Interface of Utils contract
contract IUtils {
    function call_return(address c, bytes _method, uint _val) public view returns (uint answer);
}
