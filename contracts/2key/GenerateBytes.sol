pragma solidity ^0.4.24;

contract GenerateBytes {

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
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    function addressToString(address _addr) public pure returns(string) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    function getJson(address converter, uint a, uint b, uint c) public view returns (string){
        string memory conv = addressToString(converter);
        string memory first = "{ converter: ";
        string memory second = ", conversionCreatedAt: ";
        string memory third = ", conversionAmountETH: ";
        string memory fourth =  ", internalId: ";
        string memory fifth = ";";
        string memory sol = strConcat(first, conv, "","","");
        return sol;

    }
    /*
    converter address, conversionCreatedAt, internalId, conversionAmountETHWei ";"
*/

//    function convert(address converter, uint conversionCreatedAt, uint internalId, uint conversionAmountETH) public view returns (string) {
//        string memory fin = "{ converterAddress : " + toString(converter) + ", conversionCreatedAt: " +
//        uintToString(conversionCreatedAt) + ", conversionAmountETH: " + uintToString(conversionAmount) +
//        ", internalId: " + uintToString(internalId) + "}";
//        return fin;
//    }




}
//import "../serialization/Seriality.sol";
//
//contract Serialize is Seriality{
//
//    function uintToString(uint v) constant returns (string str) {
//        uint maxlength = 100;
//        bytes memory reversed = new bytes(maxlength);
//        uint i = 0;
//        while (v != 0) {
//            uint remainder = v % 10;
//            v = v / 10;
//            reversed[i++] = byte(48 + remainder);
//        }
//        bytes memory s = new bytes(i + 1);
//        for (uint j = 0; j <= i; j++) {
//            s[j] = reversed[i - j];
//        }
//        str = string(s);
//    }
//
//    function addressToAsciiString(address _address) public constant returns (string) {
//        bytes memory s = new bytes(40);
//        for (uint i = 0; i < 20; i++) {
//            byte b = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
//            byte hi = byte(uint8(b) / 16);
//            byte lo = byte(uint8(b) - 16 * uint8(hi));
//            s[2 * i] = char(hi);
//            s[2 * i + 1] = char(lo);
//        }
//        return string(s);
//    }
//    function char(byte b) returns (byte c) {
//        if (b < 10) return byte(uint8(b) + 0x30);
//        else return byte(uint8(b) + 0x57);
//    }
//
//
//
//    function getBytes(address converter, uint conversionCreatedAt, uint internalId, uint conversionAmountETH) public view returns(bytes serialized){
////        string memory a = addressToAsciiString(converter);
//        string memory b = uintToString(conversionCreatedAt);
//        string memory c = uintToString(internalId);
//        string memory d = uintToString(conversionAmountETH);
//
//        //64 byte is needed for safe storage of a single string.
//        //((endindex - startindex) + 1) is the number of strings we want to pull out.
//        uint offset = 64*(4);
//
//        bytes memory buffer = new  bytes(offset);
//        string memory out1  = new string(32);
//
////        out1 = converter;
//        addressToBytes(offset, converter, buffer);
//        offset -= sizeOfAddress();
//        out1 = b;
//        stringToBytes(offset, bytes(out1), buffer);
//        offset -= sizeOfString(out1);
//        out1 = c;
//        stringToBytes(offset, bytes(out1), buffer);
//        offset -= sizeOfString(out1);
//        out1 = d;
//        stringToBytes(offset, bytes(out1), buffer);
//        offset -= sizeOfString(out1);
//
//
//
//        //        for(uint i = startindex; i <= endindex; i++){
////            out1 = arr[i];
////
////            stringToBytes(offset, bytes(out1), buffer);
////            offset -= sizeOfString(out1);
////        }
//
//        return (buffer);
//    }
//}

