pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/storage-contracts/ITwoKeyMaintainersRegistryStorage.sol";
import "../upgradability/Upgradeable.sol";

/**
 * @author Nikola Madjarevic
 */
contract TwoKeyMaintainersRegistry is Upgradeable {

    // Flag which will make function setInitialParams callable only once
    bool initialized;

    address public TWO_KEY_SINGLETON_REGISTRY;

    ITwoKeyMaintainersRegistryStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function which can be called only once, and is used as replacement for a constructor
     * @param _twoKeySingletonRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     * @param _maintainers is the array of initial maintainers we'll kick off contract with
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage,
        address [] _maintainers
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        PROXY_STORAGE_CONTRACT = ITwoKeyMaintainersRegistryStorage(_proxyStorage);


        //Deployer is also maintainer
        addMaintainer(msg.sender);

        // Store all maintainers inside array (just for getter purposes)
        PROXY_STORAGE_CONTRACT.setAddressArray(keccak256("maintainers"), _maintainers);

        //Set initial maintainers
        for(uint i=0; i<_maintainers.length; i++) {
            addMaintainer(_maintainers[i]);
        }

        //Once this executes, this function will not be possible to call again.
        initialized = true;
    }


    /**
     * @notice Modifier to restrict calling the method to anyone but twoKeyAdmin
     */
    function onlyTwoKeyAdmin(address sender) public view returns (bool) {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(sender == address(twoKeyAdmin));
        return true;
    }

    /**
     * @notice Function which will determine if address is maintainer
     */
    function onlyMaintainer(address _sender) public view returns (bool) {
        return isMaintainer(_sender);
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
        require(onlyTwoKeyAdmin(msg.sender) == true);
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;

        for(uint i=0; i<numberOfMaintainers; i++) {
            addMaintainer(_maintainers[i]);
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
        require(onlyTwoKeyAdmin(msg.sender) == true);
        //If state variable, .balance, or .length is used several times, holding its value in a local variable is more gas efficient.
        uint numberOfMaintainers = _maintainers.length;
        for(uint i=0; i<numberOfMaintainers; i++) {

            removeMaintainer(_maintainers[i]);
        }
    }

    /**
     * @notice Function to get all maintainers set DURING CAMPAIGN CREATION
     */
    function getAllMaintainers()
    public
    view
    returns (address[])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(keccak256("maintainers"));
    }

    /**
     * @notice Function to check if address is maintainer
     * @param _address is the address we're checking if it's maintainer or not
     */
    function isMaintainer(
        address _address
    )
    internal
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256("isMaintainer", _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
    }

    /**
     * @notice Function which will add maintainer
     * @param _maintainer is the address of new maintainer we're adding
     */
    function addMaintainer(
        address _maintainer
    )
    internal
    {
        bytes32 keyHash = keccak256("isMaintainer", _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, true);
    }

    /**
     * @notice Function which will remove maintainer
     * @param _maintainer is the address of the maintainer we're removing
     */
    function removeMaintainer(
        address _maintainer
    )
    internal
    {
        bytes32 keyHash = keccak256("isMaintainer", _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, false);
    }

    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }



}
