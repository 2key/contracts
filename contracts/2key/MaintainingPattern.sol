pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 * @notice This is maintaining pattern supporting maintainers and twoKeyAdmin as ``central authority`` which is only eligible
 * to edit maintainers list
 */

contract MaintainingPattern {
    /**
     * Mapping which will store maintainers who are eligible to update contract state
     */
    mapping(address => bool) public isMaintainer;

    /**
     * Address of TwoKeyAdmin contract, which will be the only one eligible to manipulate the maintainers
     */
    address public twoKeyAdmin;

    /**
     * @notice Modifier to restrict calling the method to anyone but maintainers
     */
    modifier onlyMaintainer {
        require(isMaintainer[msg.sender] == true);
        _;
    }

    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    modifier onlyTwoKeyAdmin {
        require(msg.sender == address(twoKeyAdmin));
        _;
    }

    /**
     * @notice Function which can add new maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function addMaintainers(
        address [] _maintainers
    )
    public
    onlyTwoKeyAdmin
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _maintainers is the array of maintainer addresses
     */
    function removeMaintainers(
        address [] _maintainers
    )
    public
    onlyTwoKeyAdmin
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }


    function checkIfMaintainer(
        address addressToCheck
    )
    public
    {
        if(isMaintainer[addressToCheck].isValue){
            return isMaintainer[addressToCheck];
        }
        else{
            return false;
        }
    }
}
