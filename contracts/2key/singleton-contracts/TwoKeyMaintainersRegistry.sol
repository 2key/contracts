pragma solidity ^0.4.24;
import "./TwoKeyMaintainersRegistryAbstract.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyMaintainersRegistry is TwoKeyMaintainersRegistryAbstract {
    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    modifier onlyTwoKeyAdmin() {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
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
        uint numberOfMaintainersToAdd = _maintainers.length;
        for(uint i=0; i<numberOfMaintainersToAdd; i++) {
            addMaintainer(_maintainers[i]);
        }
    }

    /**
     * @notice Function which can add new core devs, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of core devs
     * @param _coreDevs is the array of core developer addresses
     */
    function addCoreDevs(
        address [] _coreDevs
    )
    public
    onlyTwoKeyAdmin
    {
        uint numberOfCoreDevsToAdd = _coreDevs.length;
        for(uint i=0; i<numberOfCoreDevsToAdd; i++) {
            addCoreDev(_coreDevs[i]);
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
            removeMaintainer(_maintainers[i]);
        }
    }

    /**
     * @notice Function which can remove some maintainers, in general it's array because this supports adding multiple addresses in 1 trnx
     * @dev only twoKeyAdmin contract is eligible to mutate state of maintainers
     * @param _coreDevs is the array of maintainer addresses
     */
    function removeCoreDevs(
        address [] _coreDevs
    )
    public
    onlyTwoKeyAdmin
    {
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfCoreDevs = _coreDevs.length;

        for(uint i=0; i<numberOfCoreDevs; i++) {
            removeCoreDev(_coreDevs[i]);
        }
    }


}
