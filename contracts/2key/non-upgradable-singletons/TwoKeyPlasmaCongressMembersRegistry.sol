pragma solidity ^0.4.24;

import "../libraries/SafeMath.sol";


/**
 * @author Nikola Madjarevic
 * github: madjarevicn
 */
contract TwoKeyPlasmaCongressMembersRegistry {
    /**
     * This contract will serve as accountant for Members inside TwoKeyPlasmaCongress
     * contract. Only contract eligible to mutate state of this contract is TwoKeyPlasmaCongress
     * TwoKeyPlasmaCongress will check for it's members from this contract.
     */

    using SafeMath for uint;

    event MembershipChanged(address member, bool isMember);

    address public TWO_KEY_PLASMA_CONGRESS;

    // The maximum voting power containing sum of voting powers of all active members
    uint256 public maxVotingPower;
    //The minimum number of voting members that must be in attendance
    uint256 public minimumQuorum;

    // Mapping to check if the member is belonging to congress
    mapping (address => bool) public isMemberInCongress;
    // Mapping address to memberId
    mapping(address => Member) public address2Member;
    // Mapping to store all members addresses
    address[] public allMembers;

    struct Member {
        address memberAddress;
        bytes32 name;
        uint votingPower;
        uint memberSince;
    }

    modifier onlyTwoKeyCongress () {
        require(msg.sender == TWO_KEY_PLASMA_CONGRESS);
        _;
    }

    /**
     * @param initialCongressMembers is the array containing addresses of initial members
     * @param memberVotingPowers is the array of unassigned integers containing voting powers respectively
     * @dev initialMembers.length must be equal votingPowers.length
     */
    constructor(
        address[] initialCongressMembers,
        bytes32[] initialCongressMemberNames,
        uint[] memberVotingPowers,
        address _twoKeyCongress
    )
    public
    {
        uint length = initialCongressMembers.length;
        for(uint i=0; i<length; i++) {
            addMemberInternal(
                initialCongressMembers[i],
                initialCongressMemberNames[i],
                memberVotingPowers[i]
            );
        }
        TWO_KEY_PLASMA_CONGRESS = _twoKeyCongress;
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
    public
    onlyTwoKeyCongress
    {
        addMemberInternal(targetMember, memberName, _votingPower);
    }

    function addMemberInternal(
        address targetMember,
        bytes32 memberName,
        uint _votingPower
    )
    internal
    {
        require(isMemberInCongress[targetMember] == false);
        minimumQuorum = allMembers.length;
        maxVotingPower = maxVotingPower.add(_votingPower);
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
    public
    onlyTwoKeyCongress
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

        // Move the lest member to this place
        allMembers[i] = allMembers[length-1];

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
        minimumQuorum = minimumQuorum.sub(1);
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
        Member memory _member = address2Member[_memberAddress];
        return _member.votingPower;
    }

    /**
     * @notice Function which will be exposed and congress will use it as "modifier"
     * @param _address is the address we're willing to check if it belongs to congress
     * @return true/false depending if it is either a member or not
     */
    function isMember(
        address _address
    )
    public
    view
    returns (bool)
    {
        return isMemberInCongress[_address];
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

    /// @notice Function to get addresses of all members in congress
    /// @return array of addresses
    function getAllMemberAddresses()
    public
    view
    returns (address[])
    {
        return allMembers;
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
}
