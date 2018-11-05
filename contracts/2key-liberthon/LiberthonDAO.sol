pragma solidity ^0.4.24;

import "./MemberTypes.sol";


/**
    Liberthon hackathon DAO contract
    @author Nikola Madjarevic
*/
contract LiberthonDAO is MemberTypes {

    string public organizationName;
    address[] founders;
    Member[] members;
    uint numOfMembers;

    mapping(address => Member) addressToMember;
    mapping(address => MemberType) addressToType;
    mapping(bytes32 => Member[]) memberTypeToMembers;

    /**
        Member username, firstname, lastname, and countryOfResidence will be limited to length of 32 ASCII chars
    */
    struct Member {
        bytes32 username;
        bytes32 firstName;
        bytes32 lastName;
        bytes32 countryOfResidence;
        uint votingPower;
    }

    struct VotingCampaign {
        address creator;
        address[] addressesVoted;
        string description;
        uint votesYes;
        uint votesNo;
        uint votingPowerYes;
        uint votingPowerNo;
    }









}
