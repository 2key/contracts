pragma solidity ^0.4.24;

/**
    Contract where we'll store the enumerator
    @author Nikola Madjarevic
*/
contract MemberTypes {

    enum MemberType {
        PRESIDENT,
        PRIME_MINISTER,
        MINISTER,
        PARLIAMENT_MEMBER,
        CONGRESS_MEMBER,
        SENATE_MEMBER,
        CITIZEN,
        MAYOR,
        EX_PAT,
        NOT_MEMBER
    }

    /**
        @notice Function to convert member type from bytes format to enum format
        @param memberType is the type of the member, if not existing, function will revert
        @return MemberType
    */
    function convertToTypeFromBytes(bytes32 memberType) public pure returns (MemberType) {
        bytes32 not_member = bytes32(0);
        if(memberType == bytes32("PRESIDENT")) {
            return MemberType.PRESIDENT;
        } else if(memberType == bytes32("PRIME_MINISTER")) {
            return MemberType.PRIME_MINISTER;
        } else if(memberType == bytes32("MINISTER")) {
            return MemberType.MINISTER;
        } else if(memberType == bytes32("PARLIAMENT_MEMBER")) {
            return MemberType.PARLIAMENT_MEMBER;
        } else if(memberType == bytes32("CONGRESS_MEMBER")) {
            return MemberType.CONGRESS_MEMBER;
        } else if(memberType == bytes32("SENATE_MEMBER")) {
            return MemberType.SENATE_MEMBER;
        } else if(memberType == bytes32("CITIZEN")) {
            return MemberType.CITIZEN;
        } else if(memberType == bytes32("MAYOR")) {
            return MemberType.MAYOR;
        } else if(memberType == bytes32("EX_PAT")) {
            return MemberType.EX_PAT;
        } else if(memberType == not_member) {
            return MemberType.NOT_MEMBER;
        }
        revert();
    }

    function convertTypeToBytes(MemberType memberType) public pure returns (bytes32) {
        if(memberType == MemberType.PRESIDENT) {
            return bytes32("PRESIDENT");
        } else if(memberType == MemberType.PRIME_MINISTER) {
            return bytes32("PRIME_MINISTER");
        } else if(memberType == MemberType.MINISTER) {
            return bytes32("MINISTER");
        } else if(memberType == MemberType.PARLIAMENT_MEMBER) {
            return bytes32("PARLIAMENT_MEMBER");
        } else if(memberType == MemberType.CONGRESS_MEMBER) {
            return bytes32("CONGRESS_MEMBER");
        } else if(memberType == MemberType.SENATE_MEMBER) {
            return bytes32("SENATE_MEMBER");
        } else if(memberType == MemberType.CITIZEN) {
            return bytes32("CITIZEN");
        } else if(memberType == MemberType.CITIZEN) {
            return bytes32("MAYOR");
        } else if(memberType == MemberType.CITIZEN) {
            return bytes32("EX_PAT");
        }
    }

}
