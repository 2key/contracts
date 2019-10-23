pragma solidity ^0.4.24;

import "../libraries/SafeMath.sol";

contract TwoKeyCongress {

    event ReceivedEther(address sender, uint amount);

    using SafeMath for uint;

    bool initialized;

    // The maximum voting power containing sum of voting powers of all active members
    uint256 maxVotingPower;
    //The minimum number of voting members that must be in attendance
    uint256 public minimumQuorum;
    //Period length for voting
    uint256 public debatingPeriodInMinutes;
    //Array of proposals
    Proposal[] public proposals;
    //Number of proposals
    uint public numProposals;

    mapping (address => bool) public isMemberInCongress;
    // Mapping address to memberId
    mapping(address => Member) public address2Member;
    // Mapping to store all members addresses
    address[] public allMembers;


    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, uint quorum, bool active);
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
        uint againstProposalTotal;
        uint supportingProposalTotal;
        bytes32 proposalHash;
        bytes transactionBytecode;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Member {
        address memberAddress;
        bytes32 name;
        uint votingPower;
        uint memberSince;
    }

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }

    // Modifier that allows only shareholders to vote and create new proposals
    modifier onlyMembers {
        require(isMemberInCongress[msg.sender] == true);
        _;
    }

    /**
     * @notice Function which will be called only once, immediately after contract deployment
     * @param _minutesForDebate is the number of minutes debate length
     * @param initialMembers is the array containing addresses of initial members
     * @param votingPowers is the array of unassigned integers containing voting powers respectively
     * @dev initialMembers.length must be equal votingPowers.length
     */
    constructor(
        uint256 _minutesForDebate,
        address[] initialMembers,
        bytes32[] initialMemberNames,
        uint[] votingPowers
    )
    payable
    public
    {
        changeVotingRules(0, _minutesForDebate);
        uint length = initialMembers.length;
        for(uint i=0; i<length; i++) {
            addMember(initialMembers[i], initialMemberNames[i], votingPowers[i]);
        }
        initialized = true;
    }


    /**
     * Add member
     *
     * Make `targetMember` a member named `memberName`
     *
     * @param targetMember ethereum address to be added
     * @param memberName public name for that member
     */
    function addMember(
        address targetMember,
        bytes32 memberName,
        uint _votingPower
    )
    internal
    {
        minimumQuorum = allMembers.length;
        maxVotingPower += _votingPower;
        address2Member[targetMember] = Member(
            {
                memberAddress: targetMember,
                memberSince: block.timestamp,
                votingPower: _votingPower,
                name: memberName
            }
        );
        allMembers.push(targetMember);
        isMemberInCongress[targetMember] = true;
        emit MembershipChanged(targetMember, true);
    }

    /**
     * Remove member
     *
     * @notice Remove membership from `targetMember`
     *
     * @param targetMember ethereum address to be removed
     */
    function removeMember(
        address targetMember
    )
    internal
    {
        require(isMemberInCongress[targetMember] == true);

        //Remove member voting power from max voting power
        uint votingPower = getMemberVotingPower(targetMember);
        maxVotingPower-= votingPower;

        uint length = allMembers.length;
        uint i=0;
        //Find selected member
        while(allMembers[i] != targetMember) {
            if(i == length) {
                revert();
            }
            i++;
        }
        //After member is found, remove his address from all members
        for (uint j = i; j< length - 1; j++){
            allMembers[j] = allMembers[j+1];
        }
        //After reduce array size
        delete allMembers[allMembers.length-1];

        uint newLength = allMembers.length.sub(1);
        allMembers.length = newLength;

        //Remove him from state mapping
        isMemberInCongress[targetMember] = false;

        //Remove his state to empty member
        address2Member[targetMember] = Member(
            {
                memberAddress: address(0),
                memberSince: block.timestamp,
                votingPower: 0,
                name: "0x0"
            }
        );
        //Reduce 1 member from quorum
        minimumQuorum -= 1;
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
        uint256 minutesForDebate
    )
    internal
    {
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
    public
    onlyMembers
    returns (uint proposalID)
    {
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = beneficiary;
        p.amount = weiAmount;
        p.description = jobDescription;
        p.proposalHash = keccak256(abi.encodePacked(beneficiary, weiAmount, transactionBytecode));
        p.transactionBytecode = transactionBytecode;
        p.minExecutionDate = block.timestamp + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        p.againstProposalTotal = 0;
        p.supportingProposalTotal = 0;
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
        bytes transactionBytecode
    )
    public
    onlyMembers
    returns (uint proposalID)
    {
        return newProposal(beneficiary, etherAmount, jobDescription, transactionBytecode);
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
        bytes transactionBytecode
    )
    public
    view
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
        string justificationText
    )
    public
    onlyMembers
    returns (uint256 voteID)
    {
        Proposal storage p = proposals[proposalNumber]; // Get the proposal
        require(block.timestamp <= p.minExecutionDate);
        require(!p.voted[msg.sender]);                  // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;
        voteID = p.numberOfVotes;                     // Increase the number of votes
        p.votes.push(Vote({ inSupport: supportsProposal, voter: msg.sender, justification: justificationText }));
        uint votingPower = getMemberVotingPower(msg.sender);
        if (supportsProposal) {                         // If they support the proposal
            p.supportingProposalTotal += votingPower; // Increase score
        } else {                                        // If they don't
            p.againstProposalTotal += votingPower;                          // Decrease the score
        }
        // Create a log of this event
        emit Voted(proposalNumber,  supportsProposal, msg.sender, justificationText);
        return voteID;
    }

    function getVoteCount(
        uint256 proposalNumber
    )
    onlyMembers
    public
    view
    returns(uint256 numberOfVotes, uint256 supportingProposalTotal, uint256 againstProposalTotal, string description)
    {
        require(proposals[proposalNumber].proposalHash != 0);
        numberOfVotes = proposals[proposalNumber].numberOfVotes;
        supportingProposalTotal = proposals[proposalNumber].supportingProposalTotal;
        againstProposalTotal = proposals[proposalNumber].againstProposalTotal;
        description = proposals[proposalNumber].description;
    }

    /// Basic getter function
    function getMemberInfo()
    public
    view
    returns (address, bytes32, uint, uint)
    {
        Member memory member = address2Member[msg.sender];
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
    function executeProposal(
        uint proposalNumber,
        bytes transactionBytecode
    )
    public
    {
        Proposal storage p = proposals[proposalNumber];

        require(
//            block.timestamp > p.minExecutionDate  &&                             // If it is past the voting deadline
             !p.executed                                                         // and it has not already been executed
            && p.proposalHash == keccak256(abi.encodePacked(p.recipient, p.amount, transactionBytecode))  // and the supplied code matches the proposal
            && p.numberOfVotes >= minimumQuorum.sub(1) // and a minimum quorum has been reached...
            && uint(p.supportingProposalTotal) >= maxVotingPower.mul(51).div(100) // Total support should be >= than 51%
        );

        // ...then execute result
        p.executed = true; // Avoid recursive calling
        p.proposalPassed = true;

        // Fire Events
        emit ProposalTallied(proposalNumber, p.numberOfVotes, p.proposalPassed);

//         Call external function
        require(p.recipient.call.value(p.amount)(transactionBytecode));
    }


    /// @notice Function getter for voting power for specific member
    /// @param _memberAddress is the address of the member
    /// @return integer representing voting power
    function getMemberVotingPower(
        address _memberAddress
    )
    public
    view
    returns (uint)
    {
        Member memory _member = address2Member[msg.sender];
        return _member.votingPower;
    }

    /// @notice to check if an address is member
    /// @param _member is the address we're checking for
    function checkIsMember(
        address _member
    )
    public
    view
    returns (bool)
    {
        return isMemberInCongress[_member];
    }


    /// @notice Getter for maximum voting power
    /// @return maxVotingPower
    function getMaxVotingPower()
    public
    view
    returns (uint)
    {
        return maxVotingPower;
    }

    /// @notice Getter for length for how many members are currently
    /// @return length of members
    function getMembersLength()
    public
    view
    returns (uint)
    {
        return allMembers.length;
    }


    /// @notice Function to get major proposal data
    /// @param proposalId is the id of proposal
    /// @return tuple containing all the data for proposal
    function getProposalData(
        uint proposalId
    )
    public
    view
    returns (uint,string,uint,bool,uint,uint,uint,bytes)
    {
        Proposal memory p = proposals[proposalId];
        return (p.amount, p.description, p.minExecutionDate, p.executed, p.numberOfVotes, p.supportingProposalTotal, p.againstProposalTotal, p.transactionBytecode);
    }

    /// @notice Function to get addresses of all members in congress
    /// @return array of addresses
    function getAllMemberAddresses()
    public
    view
    returns (address[])
    {
        return allMembers;
    }

    /// @notice Fallback function
    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

