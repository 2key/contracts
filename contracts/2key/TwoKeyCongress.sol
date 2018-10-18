pragma solidity ^0.4.24;

import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

// TODO: OnlyMember should be actually onlyContract by itself
// Interface for ERC20 token to use method transferFrom
interface Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

// Contract TokenRecipient
contract TokenRecipient {
    event ReceivedEther(address sender, uint amount);
    event ReceivedTokens(address _from, uint256 _value, address _token, bytes _extraData);

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        Token t = Token(_token);
        require(t.transferFrom(_from, this, _value));
        emit ReceivedTokens(_from, _value, _token, _extraData);
    }

    function () payable  public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

//TODO: This contract doesn't need to be ownable, since there's only single deployment stuff and after that everything is up
// to the members

contract TwoKeyCongress is Ownable, TokenRecipient {

	using SafeMath for uint;

    //The minimum number of voting members that must be in attendance
    uint256 public minimumQuorum;
    //Period length for voting
    uint256 public debatingPeriodInMinutes;
    //Array of proposals
    Proposal[] public proposals;
    //Number of proposals
    uint public numProposals;
    // Mapping address to memberId
    mapping (address => uint) public memberId;
    // Array of members
    Member[] public members;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, int result, uint quorum, bool active);
    event MembershipChanged(address member, bool isMember);
    event ChangeOfRules(uint256 _newMinimumQuorum, uint256 _newDebatingPeriodInMinutes);

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint minExecutionDate;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address memberAddress;
        string name;
        int votingPower;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyMembers {
        require(memberId[msg.sender] != 0);
        _;
    }


    constructor(
        uint256 _minimumQuorumForProposals,
        uint256 _minutesForDebate, address[] initialMembers) Ownable() payable public {
        changeVotingRules(_minimumQuorumForProposals, _minutesForDebate);
        addMember(initialMembers[0], 'Eitan');
        addMember(initialMembers[1], 'Kiki');
        // It is necessary to add an empty first member
//        addMember(0,'','');
//        // and let's add the board-member, to save a step later
//        addMember(0, "Eitan", 'board-member');
        //        addMember(owner, 'founder');
    }

    /// @notice Function where member can replace it's own address
    /// @dev member can change only it's own address
    /// @param _newMemberAddress is the new address we'd like to set for us
    function replaceMemberAddress(address _newMemberAddress) public {
        require(_newMemberAddress != address(0));
        uint id = memberId[msg.sender];
        require(id != 0); //requiring that member already exists
        memberId[msg.sender] = 0;
        memberId[_newMemberAddress] = id;
        Member memory _currentMember = members[id];
        _currentMember.memberAddress = _newMemberAddress;
        members[id] = _currentMember;
    }
    /**
     * Add member
     *
     * Make `targetMember` a member named `memberName`
     *
     * @param targetMember ethereum address to be added
     * @param memberName public name for that member
     */
    function addMember(address targetMember, string memberName) internal {
        uint id = memberId[targetMember];
        if (id == 0) {
            memberId[targetMember] = members.length;
            id = members.length++;
        }

        members[id] = Member({memberAddress: targetMember, memberSince: now, votingPower: 1, name: memberName});
        emit MembershipChanged(targetMember, true);
    }

    /**
     * Remove member
     *
     * @notice Remove membership from `targetMember`
     *
     * @param targetMember ethereum address to be removed
     */
    function removeMember(address targetMember) internal {
        require(memberId[targetMember] != 0);

        for (uint i = memberId[targetMember]; i<members.length-1; i++){
            members[i] = members[i+1];
        }
        delete members[members.length-1];
        memberId[targetMember] = 0;
        members.length--;
    }

    /**
     * Change voting rules
     *
     * Make so that proposals need to be discussed for at least `minutesForDebate/60` hours,
     * have at least `minimumQuorumForProposals` votes, and have 50% + `marginOfVotesForMajority` votes to be executed
     *
     * @param minimumQuorumForProposals how many members must vote on a proposal for it to be executed
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     */
    function changeVotingRules(
        uint256 minimumQuorumForProposals,
        uint256 minutesForDebate) internal {
        minimumQuorum = minimumQuorumForProposals;
        debatingPeriodInMinutes = minutesForDebate;

        emit ChangeOfRules(minimumQuorumForProposals, minutesForDebate);
    }

    /**
     * Add Proposal
     *
     * Propose to send `weiAmount / 1e18` ether to `beneficiary` for `jobDescription`. `transactionBytecode ? Contains : Does not contain` code.
     *
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send, in wei
     * @param jobDescription Description of job
     * @param transactionBytecode bytecode of transaction
     */
    function newProposal(
        address beneficiary,
        uint weiAmount,
        string jobDescription,
        bytes transactionBytecode)
        onlyMembers public
        returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = jobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
        p.minExecutionDate = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.currentResult = 0;
        emit ProposalAdded(proposalID, beneficiary, weiAmount, jobDescription);
        numProposals = proposalID+1;

        return proposalID;
    }

    /**
     * Add proposal in Ether
     *
     * Propose to send `etherAmount` ether to `beneficiary` for `jobDescription`. `transactionBytecode ? Contains : Does not contain` code.
     * This is a convenience function to use if the amount to be given is in round number of ether units.
     *
     * @param beneficiary who to send the ether to
     * @param etherAmount amount of ether to send
     * @param jobDescription Description of job
     * @param transactionBytecode bytecode of transaction
     */
    function newProposalInEther(
        address beneficiary,
        uint etherAmount,
        string jobDescription,
        bytes transactionBytecode)
        onlyMembers public
        returns (uint proposalID)
    {
        return newProposal(beneficiary, etherAmount * 1 ether, jobDescription, transactionBytecode);
    }

    /**
     * Check if a proposal code matches
     *
     * @param proposalNumber ID number of the proposal to query
     * @param beneficiary who to send the ether to
     * @param weiAmount amount of ether to send
     * @param transactionBytecode bytecode of transaction
     */
    function checkProposalCode(
        uint proposalNumber,
        address beneficiary,
        uint weiAmount,
        bytes transactionBytecode)
        constant public
        returns (bool codeChecksOut)
    {
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
    }

    /**
     * Log a vote for a proposal
     *
     * Vote `supportsProposal? in support of : against` proposal #`proposalNumber`
     *
     * @param proposalNumber number of proposal
     * @param supportsProposal either in favor or against it
     * @param justificationText optional justification text
     */
    function vote(
        uint proposalNumber,
        bool supportsProposal,
        string justificationText)
        onlyMembers public
        returns (uint256 voteID)
    {
        Proposal storage p = proposals[proposalNumber]; // Get the proposal
        require(now <= p.minExecutionDate);
        require(!p.voted[msg.sender]);                  // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;
        voteID = p.numberOfVotes;                     // Increase the number of votes
        p.votes.push(Vote({ inSupport: supportsProposal, voter: msg.sender, justification: justificationText }));
        int votingPower = getMemberVotingPower(msg.sender);
        if (supportsProposal) {                         // If they support the proposal
            p.currentResult+= votingPower;                          // Increase score
        } else {                                        // If they don't
            p.currentResult-= votingPower;                          // Decrease the score
        }
        // Create a log of this event
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return voteID;
    }

    function getVoteCount(uint256 proposalNumber) onlyMembers public view returns(uint256 numberOfVotes, int256 currentResult, string description) {
        require(proposals[proposalNumber].proposalHash != 0);
        numberOfVotes = proposals[proposalNumber].numberOfVotes;
        currentResult = proposals[proposalNumber].currentResult;
        description = proposals[proposalNumber].description;
    }

    function getMemberInfo() public view returns (address, string, int, uint) {
        uint _id = memberId[msg.sender];
        Member memory member = members[_id];
        return (member.memberAddress, member.name, member.votingPower, member.memberSince);
    }

    /**
     * Finish vote
     *
     * Count the votes proposal #`proposalNumber` and execute it if approved
     *
     * @param proposalNumber proposal number
     * @param transactionBytecode optional: if the transaction contained a bytecode, you need to send it
     */
    function executeProposal(uint proposalNumber, bytes transactionBytecode) public {
        Proposal storage p = proposals[proposalNumber];

        require(
            now > p.minExecutionDate                                            // If it is past the voting deadline
            && !p.executed                                                         // and it has not already been executed
            && p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode))  // and the supplied code matches the proposal
            && p.numberOfVotes.mul(100).div(members.length) >= minimumQuorum // and a minimum quorum has been reached...
        );

        // ...then execute result
        p.executed = true; // Avoid recursive calling
        require(p.recipient.call.value(p.amount)(transactionBytecode));

        p.proposalPassed = true;


        // Fire Events
        emit ProposalTallied(proposalNumber, p.currentResult, p.numberOfVotes, p.proposalPassed);
    }

    function getMemberVotingPower(address _memberAddress) public view returns (int) {
        uint _memberId = memberId[_memberAddress];
        Member memory _member = members[_memberId];
        return _member.votingPower;
    }

    function getMemberId() public view returns (uint) {
        return memberId[msg.sender];
    }

    function () payable public {
        
    }

}
