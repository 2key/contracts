pragma solidity ^0.4.24;

/**
 * @author Nikola Madjarevic
 * @notice This is maintaining pattern supporting maintainers and twoKeyAdmin as ``central authority`` which is only eligible
 * to edit maintainers list
 */

contract TwoKeyMaintainersRegistry {
    /**
     * Flag which will make function setInitialParams callable only once
     */
    bool initialized;

    /**
     * Mapping which will store maintainers who are eligible to update contract state
     */
    mapping(address => bool) public isMaintainer;

    /**
     * Address of TwoKeyAdmin contract, which will be the only one eligible to manipulate the maintainers
     */
    address public twoKeyAdmin;

    /**
     * @notice Function which can be called only once, and is used as replacement for a constructor
     * @param _twoKeyAdmin is the address of twoKeyAdmin contract as central authority
     * @param _maintainers is the array of initial maintainers we'll kick off contract with
     */
    function setInitialParams(
        address _twoKeyAdmin,
        address [] _maintainers
    )
    public
    {
        require(initialized == false);

        //Set TwoKeyAdmin contract
        twoKeyAdmin = _twoKeyAdmin;

        //Set deployer to be also a maintainer
        isMaintainer[msg.sender] = true;

        //Set initial maintainers
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }

        //Once this executes, this function will not be possible to call again.
        initialized = true;
    }

    /**
     * @notice Function to restrict calling the method to anyone but maintainers
     */
    function onlyMaintainer(address _sender) public view returns (bool) {
        return isMaintainer[_sender];
    }

    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    function onlyTwoKeyAdmin() public view returns (bool) {
        require(msg.sender == address(twoKeyAdmin));
        return true;
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
    {
        require(onlyTwoKeyAdmin() == true);
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
    {
        require(onlyTwoKeyAdmin() == true);
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {
            isMaintainer[_maintainers[i]] = false;
        }
    }

}
