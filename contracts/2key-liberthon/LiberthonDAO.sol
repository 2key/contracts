pragma solidity ^0.4.24;

import "./MemberTypes.sol";


/**
    Liberthon hackathon DAO contract
    @author Nikola Madjarevic
*/
contract LiberthonDAO is MemberTypes {

    /**
        Nation details and rules
    */
    string public nationName;


    address[] founders;
    Member[] members;
    uint numOfMembers;

    mapping(address => uint) memberAddressToId;
    mapping(uint => Member) idToMember;
    mapping(address => MemberType) addressToType;
    mapping(bytes32 => Member[]) memberTypeToMembers;

    /**
        Member username, firstname, lastname, and countryOfResidence will be limited to length of 32 ASCII chars
    */
    struct Member {
        address memberAddress;
        bytes32 username;
        bytes32 firstName;
        bytes32 lastName;
        MemberType type;
    }











}
