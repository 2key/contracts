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
    bytes32 public ipfsForConstitution;

    Member[] members;
    uint numOfMembers = 0;

    mapping(address => uint) public memberAddressToId;
    mapping(uint => Member) public idToMember;
    mapping(bytes32 => Member[]) public memberTypeToMembers;

    /**
        Member username, firstname, lastname, and countryOfResidence will be limited to length of 32 ASCII chars
    */
    struct Member {
        address memberAddress;
        bytes32 username;
        bytes32 firstName;
        bytes32 lastName;
        MemberType memberType;
    }
    /**
     "Srbija", "0x12345678", ["0x14723a09acff6d2a60dcdf7aa4aff308fddc160c","0xca35b7d915458ef540ade6068dfe2f44e8fa733c"],
         ["0x1233","0x123456"],["0x322155","0x234136"],["0x654326","0xf2135121"],["0x505245534944454e540000000000000000000000000000000000000000000000","0x4d494e4953544552000000000000000000000000000000000000000000000000"]
     *
     */
    constructor(
        string _nationName,
        bytes32 _ipfsHashForConstitution,
        address[] initialMembersAddresses,
        bytes32[] initialUsernames,
        bytes32[] initialFirstNames,
        bytes32[] initialLastNames,
        bytes32[] initialMemberTypes
    ) public  {
        // Requiring that for all members are all the informations passed
        require(initialMembersAddresses.length == initialUsernames.length &&
        initialUsernames.length == initialFirstNames.length &&
        initialFirstNames.length == initialLastNames.length &&
        initialLastNames.length == initialMemberTypes.length);

        uint length = initialMembersAddresses.length;
        for(uint i=0; i<length; i++) {
            addMember(initialMembersAddresses[i],initialUsernames[i],initialFirstNames[i],initialLastNames[i],initialMemberTypes[i]);
        }
        nationName = _nationName;
        ipfsForConstitution = _ipfsHashForConstitution;
    }

    function addMember(
        address _memberAddress,
        bytes32 memberUsername,
        bytes32 memberFirstName,
        bytes32 memberLastName,
        bytes32 memberType)
    internal {
        MemberType _memberType = convertToTypeFromBytes(memberType);

        Member memory m = Member({
            memberAddress: _memberAddress,
            username: memberUsername,
            firstName: memberFirstName,
            lastName: memberLastName,
            memberType: _memberType
        });

        memberTypeToMembers[memberType].push(m);
        members.push(m);
        memberAddressToId[_memberAddress] = numOfMembers;
        idToMember[numOfMembers] = m;
        numOfMembers++;
    }

}
