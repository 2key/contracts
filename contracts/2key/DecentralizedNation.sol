pragma solidity ^0.4.24;

import "../interfaces/ITwoKeyWeightedVoteContract.sol";
import "../interfaces/ITwoKeyRegistry.sol";

contract DecentralizedNation {

    string public nationName;
    bytes32 public ipfsForConstitution;
    bytes32 public ipfsHashForDAOPublicInfo;

    bytes32[] public memberTypes;

    Member[] members;
    uint numOfMembers;

    bool initialized = false;

    mapping(address => uint) public memberId;
    mapping(bytes32 => uint) public limitOfMembersPerType;
    mapping(bytes32 => address[]) public memberTypeToMembers;

    uint numberOfVotingCamapignsAndPetitions;

    mapping(address => uint) votingPoints;
    mapping(address => uint) numberOfVotingPetitionDuringLastRefill;

    mapping(bytes32 => AuthoritySchema) memberTypeToAuthoritySchemaToChange;

    address [] public nationalVotingCampaigns;  //*
    //TODO we should probably add national petitionn campaigns, and a default authoritySchema, that requires congress to vote (geenrates a new mendatory votinng campaign for congress
    //members only, that has a end date and required authority schema, that if is not reached (miinmal voters etc..), the petition becomes law)

    mapping(address => NationalVotingCampaign) public votingContractAddressToNationalVotingCampaign;

    //TODO need to add the national petition campaigns, they should have a standard authority schema, and get auto-upgraded to a congressional voting campaign if the autority
    //schema is satisfied

    //TODO any voting that didn't meet the required authority schema, goes into the history/archive
    //TODO any petition which meets the national interest criteria will graduate to a congress veto campaign, which can reject if there is vast majority against

    address[] rejectedVotings;
    address[] rejectedPetitions;

    address twoKeyRegistryContract;

    struct NationalVotingCampaign {
        string votingReason; //simple text to fulfill screen?
        address targetOfVoting;
        bytes32 newRole;
        bool finished;
        uint votesYes;
        uint votesNo;
        uint votingResult;
        uint votingCampaignLengthInDays;
    }


    struct Member {
        address memberAddress;
        bytes32 username;
        bytes32 fullName;
        bytes32 email;
        bytes32 memberType;
    }


    struct AuthoritySchema {
        bytes32[] memberTypesEligibleToVote;
        uint minimalNumberOfVoters;
        uint minimalPercentToBeReached;
    }


    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }


    constructor(
        string _nationName,
        bytes32 _ipfsHashForConstitution,
        bytes32 _ipfsHashForDAOPublicInfo,
        address[] initialMembersAddresses,
        bytes32[] initialMemberTypes,
        address _twoKeyRegistry
    ) public  {

        memberTypes.push(bytes32("FOUNDERS"));
        twoKeyRegistryContract = _twoKeyRegistry;

        uint length = initialMembersAddresses.length;

        addMember(0,bytes32(0));

        for(uint i=0; i<length; i++) {
            addMember(
                initialMembersAddresses[i],
                memberTypes[0]);
        }

        for(uint j=0; j<initialMemberTypes.length; j++) {
            memberTypes.push(initialMemberTypes[j]);
        }

        nationName = _nationName;
        ipfsForConstitution = _ipfsHashForConstitution;
        ipfsHashForDAOPublicInfo = _ipfsHashForDAOPublicInfo;
        initialized = true;
    }


    function addMember(
        address _memberAddress,
        bytes32 _memberType)
    internal {
        if(members.length > 0) {
            require(ITwoKeyRegistry(twoKeyRegistryContract).checkIfUserExists(_memberAddress));
        }
        if(initialized) {
            require(limitOfMembersPerType[_memberType] < memberTypeToMembers[_memberType].length);
        }

        bytes32 memberUsername;
        bytes32 memberFullName;
        bytes32 memberEmail;

        (memberUsername,memberFullName,memberEmail) = ITwoKeyRegistry(twoKeyRegistryContract).getUserData(_memberAddress);
        require(checkIfMemberTypeExists(_memberType) || _memberType == bytes32(0));
        Member memory m = Member({
            memberAddress: _memberAddress,
            username: memberUsername,
            fullName: memberFullName,
            email: memberEmail,
            memberType: _memberType
        });

        members.push(m);
        memberId[_memberAddress] = numOfMembers;
        memberTypeToMembers[_memberType].push(_memberAddress);
        votingPoints[_memberAddress] = 100;
        numberOfVotingPetitionDuringLastRefill[_memberAddress] = numberOfVotingCamapignsAndPetitions;
        numOfMembers++;
    }


    function removeMember(address targetMember) internal {
        require(memberId[targetMember] != 0);
        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        memberId[targetMember] = 0;
        votingPoints[targetMember] = 0;
        members.length--;
    }


    function changeMemberType(
        address _memberAddress,
        bytes32 _newType)
    internal {
        require(memberId[_memberAddress] != 0);
        require(checkIfMemberTypeExists(_newType));

        AuthoritySchema memory schema = memberTypeToAuthoritySchemaToChange[_newType];
        uint id = memberId[_memberAddress];
        Member memory m = members[id];
        m.memberType = _newType;
        members[id] = m;
    }

    function createAuthoritySchemaForType(
        bytes32 memberType,
        bytes32[] _memberTypesEligibleToVote,
        uint _minimalNumberOfVoters,
        uint _minimalPercentToBeReached
    ) public {
        require(checkIfMemberTypeExists(memberType));
        memberTypeToAuthoritySchemaToChange[memberType] = AuthoritySchema({
            memberTypesEligibleToVote: _memberTypesEligibleToVote,
            minimalNumberOfVoters: _minimalNumberOfVoters,
            minimalPercentToBeReached: _minimalPercentToBeReached
        });
    }


    function setLimitForMembersPerType(bytes32[] types, uint[] limits) public {
        require(types.length == limits.length);
        for(uint i=0; i<types.length; i++) {
            limitOfMembersPerType[types[i]] = limits[i];
        }
    }


    function checkIfMemberTypeExists(bytes32 memberType) public view returns (bool) {
        for(uint i=0; i<memberTypes.length; i++) {
            if(memberTypes[i] == memberType) {
                return true;
            }
        }
        return false;
    }

    /// @notice Function to return all the members from Liberland
    function getAllMembers() public view returns (address[],bytes32[],bytes32[],bytes32[], bytes32[]) {
        uint length = members.length - 1;
        address[] memory allMemberAddresses = new address[](length);
        bytes32[] memory allMemberUsernames = new bytes32[](length);
        bytes32[] memory allMemberFullNames = new bytes32[](length);
        bytes32[] memory allMemberEmails = new bytes32[](length);
        bytes32[] memory allMemberTypes = new bytes32[](length);

        for(uint i=1; i<length + 1; i++) {
            Member memory m = members[i];
            allMemberAddresses[i-1] = m.memberAddress;
            allMemberUsernames[i-1] = m.username;
            allMemberFullNames[i-1] = m.fullName;
            allMemberEmails[i-1] = m.email;
            allMemberTypes[i-1] = m.memberType;
        }

        return (allMemberAddresses, allMemberUsernames, allMemberFullNames, allMemberEmails, allMemberTypes);
    }


    function getAllMembersForType(bytes32 memberType) public view returns (address[]) {
        return memberTypeToMembers[memberType];
    }

    function getLimitForType(bytes32 memberType) public view returns(uint) {
        return limitOfMembersPerType[memberType];
    }

    function getMembersVotingPoints(address _memberAddress) public view returns (uint) {
        return votingPoints[_memberAddress];
    }

    function getAuthorityToChangeSelectedMemberType(bytes32 memberType) public view returns (bytes32[], uint,uint) {
        AuthoritySchema memory schema = memberTypeToAuthoritySchemaToChange[memberType];
        return(schema.memberTypesEligibleToVote, schema.minimalNumberOfVoters, schema.minimalPercentToBeReached);
    }

    function startVotingForChanging(
        string description,
        address _memberToChangeRole,
        bytes32 _newRole,
        uint _votingCampaignLengthInDays,
        address twoKeyWeightedVoteContract
    ) public {
        require(checkIfMemberTypeExists(_newRole));
        NationalVotingCampaign memory nvc = NationalVotingCampaign({
            votingReason: description,
            targetOfVoting: _memberToChangeRole,
            newRole: _newRole,
            finished: false,
            votesYes: 0,
            votesNo: 0,
            votingResult: 0,
            votingCampaignLengthInDays: block.timestamp + _votingCampaignLengthInDays * (1 days)
        });

        ITwoKeyWeightedVoteContract(twoKeyWeightedVoteContract).setValid();
        votingContractAddressToNationalVotingCampaign[twoKeyWeightedVoteContract] = nvc;
        nationalVotingCampaigns.push(twoKeyWeightedVoteContract);
        numberOfVotingCamapignsAndPetitions++;
    }


    function getResultsForVoting(uint nvc_id) public view returns (string) {
        address nationalVotingCampaignContractAddress = nationalVotingCampaigns[nvc_id];
        NationalVotingCampaign memory nvc = votingContractAddressToNationalVotingCampaign[nationalVotingCampaignContractAddress];

        string memory description = ITwoKeyWeightedVoteContract(nationalVotingCampaignContractAddress).getDescription();
        return description;
    }

    function executeVoting(uint nvc_id, bytes signature) public returns (bool) {
        //Will return true if executed or false if didn't meet the criteria so we'll be able to show to user why
        address nationalVotingCampaignContractAddress = nationalVotingCampaigns[nvc_id];
        NationalVotingCampaign memory nvc = votingContractAddressToNationalVotingCampaign[nationalVotingCampaignContractAddress];

        require(block.timestamp > nvc.votingCampaignLengthInDays);

        AuthoritySchema memory authoritySchema = memberTypeToAuthoritySchemaToChange[nvc.newRole];
        address [] memory allParticipants = ITwoKeyWeightedVoteContract(nationalVotingCampaignContractAddress).transferSig(signature);

        //TODO: Validate all Participants roles and exclude ones not eligible to vote
        //TODO: If any participant is not even a member of DAO exclude his vote
        //TODO: At the end calculate voting points and sum them
    }

}