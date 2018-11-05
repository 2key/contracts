pragma solidity ^0.4.0;

contract LiberthonDAOInterface {

    function addMember(
        address _memberAddress,
        bytes32 memberUsername,
        bytes32 memberFirstName,
        bytes32 memberLastName,
        bytes32 memberType)
    internal;

    function changeMemberType(
        address _memberAddress,
        bytes32 _newType)
    internal;

    function changeConstitution(
        bytes32 newIpfsHashForConstitution
    ) internal;




}
