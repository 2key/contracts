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
}
