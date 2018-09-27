pragma solidity ^0.4.24;

import "../serialization/Seriality.sol";

contract Serialize is Seriality {

    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function addressToAsciiString(address _address) public constant returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }
    function char(byte b) returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }



    function getBytes(address converter, uint conversionCreatedAt, uint conversionAmountETH) public view returns(bytes serialized){
//        string memory a = addressToAsciiString(converter);
        string memory b = uintToString(conversionCreatedAt);
        string memory c = uintToString(conversionAmountETH);

        //64 byte is needed for safe storage of a single string.
        //((endindex - startindex) + 1) is the number of strings we want to pull out.
        uint offset = 64*(3);

        bytes memory buffer = new  bytes(offset);
        string memory out1  = new string(32);

//        out1 = converter;
        addressToBytes(offset, converter, buffer);
        offset -= sizeOfAddress();
        out1 = b;
        stringToBytes(offset, bytes(out1), buffer);
        offset -= sizeOfString(out1);
        out1 = c;
        stringToBytes(offset, bytes(out1), buffer);
        offset -= sizeOfString(out1);




        //        for(uint i = startindex; i <= endindex; i++){
//            out1 = arr[i];
//
//            stringToBytes(offset, bytes(out1), buffer);
//            offset -= sizeOfString(out1);
//        }

        return (buffer);
    }
}

