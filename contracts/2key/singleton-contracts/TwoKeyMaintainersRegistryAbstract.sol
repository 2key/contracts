pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../libraries/SafeMath.sol";

import "../interfaces/IStructuredStorage.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";

contract TwoKeyMaintainersRegistryAbstract is Upgradeable {
    /**
     * All keys used for the storage contract.
     * Saved as a constants to avoid any potential typos
     */
    string constant _isMaintainer = "isMaintainer";
    string constant _isCoreDev = "isCoreDev";
    string constant _idToMaintainer = "idToMaintainer";
    string constant _idToCoreDev = "idToCoreDev";
    string constant _numberOfMaintainers = "numberOfMaintainers";
    string constant _numberOfCoreDevs = "numberOfCoreDevs";
    string constant _numberOfActiveMaintainers = "numberOfActiveMaintainers";
    string constant _numberOfActiveCoreDevs = "numberOfActiveCoreDevs";

    //For all math operations we use safemath
    using SafeMath for *;

    // Flag which will make function setInitialParams callable only once
    bool initialized;

    address public TWO_KEY_SINGLETON_REGISTRY;

    IStructuredStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice Function which can be called only once, and is used as replacement for a constructor
     * @param _twoKeySingletonRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     * @param _maintainers is the array of initial maintainers we'll kick off contract with
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage,
        address [] _maintainers,
        address [] _coreDevs
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;

        PROXY_STORAGE_CONTRACT = IStructuredStorage(_proxyStorage);

        //Deployer is also maintainer
        addMaintainer(msg.sender);

        //Set initial maintainers
        for(uint i=0; i<_maintainers.length; i++) {
            addMaintainer(_maintainers[i]);
        }

        //Set initial core devs
        for(uint j=0; j<_coreDevs.length; j++) {
            addCoreDev(_coreDevs[j]);
        }

        //Once this executes, this function will not be possible to call again.
        initialized = true;
    }


    /**
     * @notice Function which will determine if address is maintainer
     */
    function checkIsAddressMaintainer(address _sender) public view returns (bool) {
        return isMaintainer(_sender);
    }

    /**
     * @notice Function which will determine if address is core dev
     */
    function checkIsAddressCoreDev(address _sender) public view returns (bool) {
        return isCoreDev(_sender);
    }

    /**
     * @notice Function to get all maintainers set DURING CAMPAIGN CREATION
     */
    function getAllMaintainers()
    public
    view
    returns (address[])
    {
        uint numberOfMaintainersTotal = getNumberOfMaintainers();
        uint numberOfActiveMaintainers = getNumberOfActiveMaintainers();
        address [] memory activeMaintainers = new address[](numberOfActiveMaintainers);

        uint counter = 0;
        for(uint i=0; i<numberOfMaintainersTotal; i++) {
            address maintainer = getMaintainerPerId(i);
            if(isMaintainer(maintainer)) {
                activeMaintainers[counter] = maintainer;
                counter = counter.add(1);
            }
        }
        return activeMaintainers;
    }


    /**
     * @notice Function to get all maintainers set DURING CAMPAIGN CREATION
     */
    function getAllCoreDevs()
    public
    view
    returns (address[])
    {
        uint numberOfCoreDevsTotal = getNumberOfCoreDevs();
        uint numberOfActiveCoreDevs = getNumberOfActiveCoreDevs();
        address [] memory activeCoreDevs = new address[](numberOfActiveCoreDevs);

        uint counter = 0;
        for(uint i=0; i<numberOfActiveCoreDevs; i++) {
            address coreDev= getCoreDevPerId(i);
            if(isCoreDev(coreDev)) {
                activeCoreDevs[counter] = coreDev;
                counter = counter.add(1);
            }
        }
        return activeCoreDevs;
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
        bytes32 keyHash = keccak256(_isMaintainer, _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
    }

    /**
     * @notice Function to check if address is coreDev
     * @param _address is the address we're checking if it's coreDev or not
     */
    function isCoreDev(
        address _address
    )
    internal
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256(_isCoreDev, _address);
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

        bytes32 keyHashIsMaintainer = keccak256(_isMaintainer, _maintainer);

        // Fetch the id for the new maintainer
        uint id = getNumberOfMaintainers();

        // Generate keyHash for this maintainer
        bytes32 keyHashIdToMaintainer = keccak256(_idToMaintainer, id);

        // Representing number of different maintainers
        incrementNumberOfMaintainers();
        // Representing number of currently active maintainers
        incrementNumberOfActiveMaintainers();

        PROXY_STORAGE_CONTRACT.setAddress(keyHashIdToMaintainer, _maintainer);
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsMaintainer, true);
    }


    /**
     * @notice Function which will add maintainer
     * @param _coreDev is the address of new maintainer we're adding
     */
    function addCoreDev(
        address _coreDev
    )
    internal
    {

        bytes32 keyHashIsCoreDev = keccak256(_isCoreDev, _coreDev);

        // Fetch the id for the new core dev
        uint id = getNumberOfCoreDevs();

        // Generate keyHash for this core dev
        bytes32 keyHashIdToCoreDev= keccak256(_idToCoreDev, id);

        // Representing number of different core devs
        incrementNumberOfCoreDevs();
        // Representing number of currently active core devs
        incrementNumberOfActiveCoreDevs();

        PROXY_STORAGE_CONTRACT.setAddress(keyHashIdToCoreDev, _coreDev);
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsCoreDev, true);
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
        bytes32 keyHashIsMaintainer = keccak256(_isMaintainer, _maintainer);
        decrementNumberOfActiveMaintainers();
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsMaintainer, false);
    }

    /**
     * @notice Function which will remove maintainer
     * @param _coreDev is the address of the maintainer we're removing
     */
    function removeCoreDev(
        address _coreDev
    )
    internal
    {
        bytes32 keyHashIsCoreDev = keccak256(_isCoreDev , _coreDev);
        decrementNumberOfActiveCoreDevs();
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsCoreDev, false);
    }

    function getNumberOfMaintainers()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfMaintainers));
    }

    function getNumberOfCoreDevs()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfCoreDevs));
    }

    function getNumberOfActiveMaintainers()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfActiveMaintainers));
    }

    function getNumberOfActiveCoreDevs()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_numberOfActiveCoreDevs));
    }


    function incrementNumberOfMaintainers()
    internal
    {
        bytes32 keyHashNumberOfMaintainers = keccak256(_numberOfMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfMaintainers).add(1)
        );
    }


    function incrementNumberOfCoreDevs()
    internal
    {
        bytes32 keyHashNumberOfCoreDevs = keccak256(_numberOfCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfCoreDevs).add(1)
        );
    }


    function incrementNumberOfActiveMaintainers()
    internal
    {
        bytes32 keyHashNumberOfActiveMaintainers = keccak256(_numberOfActiveMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfActiveMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfActiveMaintainers).add(1)
        );
    }

    function incrementNumberOfActiveCoreDevs()
    internal
    {
        bytes32 keyHashNumberToActiveCoreDevs= keccak256(_numberOfActiveCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberToActiveCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberToActiveCoreDevs).add(1)
        );
    }

    function decrementNumberOfActiveMaintainers()
    internal
    {
        bytes32 keyHashNumberOfActiveMaintainers = keccak256(_numberOfActiveMaintainers);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberOfActiveMaintainers,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberOfActiveMaintainers).sub(1)
        );
    }

    function decrementNumberOfActiveCoreDevs()
    internal
    {
        bytes32 keyHashNumberToActiveCoreDevs = keccak256(_numberOfActiveCoreDevs);
        PROXY_STORAGE_CONTRACT.setUint(
            keyHashNumberToActiveCoreDevs,
            PROXY_STORAGE_CONTRACT.getUint(keyHashNumberToActiveCoreDevs).sub(1)
        );
    }

    function getMaintainerPerId(
        uint _id
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_idToMaintainer,_id));
    }


    function getCoreDevPerId(
        uint _id
    )
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_idToCoreDev,_id));
    }


    // Internal function to fetch address from TwoKeyRegistry
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

}
