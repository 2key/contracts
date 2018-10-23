pragma solidity ^0.4.24;

contract BasicStorage {

    string str;
    uint256 number;

    function myMethod(uint256 myNumber, string myString) public {
        number = myNumber;
        str = myString;
    }


    function get() public view returns (uint256, string) {
        return (number, str);
    }


    function callFunction(bytes transactionBytecode) public {
        address(this).call(transactionBytecode);
    }


}