pragma solidity ^0.4.24;

import "./MemberTypes.sol";


/**
    Liberthon hackathon DAO contract
    @author Nikola Madjarevic
*/
contract LiberthonDAO is MemberTypes {

    string public nationName;
    bytes32 public ipfsForConstitution;

    Member[] members;

    mapping(address => uint) public memberId;

    uint numOfMembers;

    struct Member {
        address memberAddress;
        bytes32 username;
        bytes32 firstName;
        bytes32 lastName;
        MemberType memberType;
    }


    struct Majority {
        MemberType lowestMemberTypeEligibleToVote;
        uint minimalNumberOfVotes;
    }

    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }

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
        addMember(0,'','','',bytes32(0));
        for(uint i=0; i<length; i++) {
            addMember(
                initialMembersAddresses[i],
                initialUsernames[i],
                initialFirstNames[i],
                initialLastNames[i],
                initialMemberTypes[i]);
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

        members.push(m);
        memberId[_memberAddress] = numOfMembers;
        numOfMembers++;
    }

    function removeMember(address targetMember) internal {
        require(memberId[targetMember] != 0);
        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        memberId[targetMember] = 0;
        members.length--;
    }

    function changeMemberType(
        address _memberAddress,
        bytes32 _newType)
    internal {
        MemberType _newMemberType = convertToTypeFromBytes(_newType);
        uint id = memberId[_memberAddress];

        Member memory m = members[id];
        m.memberType = _newMemberType;
        members[id] = m;
    }




}
