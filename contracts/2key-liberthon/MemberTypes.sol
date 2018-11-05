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
        EX_PAT
    }

    /**
        @notice Function to convert member type from bytes format to enum format
        @param memberType is the type of the member, if not existing, function will revert
        @return MemberType
    */
    function convertToTypeFromBytes(bytes32 memberType) public pure returns (MemberType) {
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
        }
        revert();
    }

}
