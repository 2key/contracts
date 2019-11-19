pragma solidity ^0.4.24;

import "../libraries/SafeMath.sol";
import "./TwoKeyCongressMembersRegistry.sol";

contract TwoKeyCongress {

    event ReceivedEther(address sender, uint amount);

    using SafeMath for uint;

    //Period length for voting
    uint256 public debatingPeriodInMinutes;
    //Array of proposals
    Proposal[] public proposals;
    //Number of proposals
    uint public numProposals;

    TwoKeyCongressMembersRegistry public twoKeyCongressMembersRegistry;

    event ProposalAdded(uint proposalID, address recipient, uint amount, string description);
    event Voted(uint proposalID, bool position, address voter, string justification);
    event ProposalTallied(uint proposalID, uint quorum, bool active);
    event ChangeOfRules(uint256 _newDebatingPeriodInMinutes);

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

    struct Vote {
        bool inSupport;
        address voter;
        string justification;
    }


    /**
     * @notice Modifier to check if the msg.sender is member of the congress
     */
    modifier onlyMembers() {
        require(twoKeyCongressMembersRegistry.isMember(msg.sender) == true);
        _;
    }

    /**
     * @param _minutesForDebate is the number of minutes debate length
     */
    constructor(
        uint256 _minutesForDebate
    )
    payable
    public
    {
        changeVotingRules(_minutesForDebate);
    }

    /**
     * @notice Function which will be called only once immediately after contract is deployed
     * @param _twoKeyCongressMembers is the address of already deployed contract
     */
    function setTwoKeyCongressMembersContract(
        address _twoKeyCongressMembers
    )
    public
    {
        require(address(twoKeyCongressMembersRegistry) == address(0));
        twoKeyCongressMembersRegistry = TwoKeyCongressMembersRegistry(_twoKeyCongressMembers);
    }


    /**
     * Change voting rules
     * @param minutesForDebate the minimum amount of delay between when a proposal is made and when it can be executed
     */
    function changeVotingRules(
        uint256 minutesForDebate
    )
    internal
    {
        debatingPeriodInMinutes = minutesForDebate;
        emit ChangeOfRules(minutesForDebate);
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
    payable
    onlyMembers
    {
        uint proposalID = proposals.length++;
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
        uint votingPower = twoKeyCongressMembersRegistry.getMemberVotingPower(msg.sender);
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
    onlyMembers
    {
        Proposal storage p = proposals[proposalNumber];
        uint minimumQuorum = twoKeyCongressMembersRegistry.minimumQuorum();
        uint maxVotingPower = twoKeyCongressMembersRegistry.maxVotingPower();
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


    /// @notice Fallback function
    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

