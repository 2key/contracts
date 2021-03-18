pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryStorage.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventory contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventory is Upgradeable {

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryStorage PROXY_STORAGE_CONTRACT;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";

    string constant _2KEYBalance = "2KEYBalance";
    string constant _USDBalance = "USDBalance";

    /**
     * @notice Function for contract initialization
     */
    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaCampaignsInventoryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice      Modifier which will be used to restrict set function calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }

    /**
     * @notice      Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }

    /**
     * @notice      Function that allocates specified amount of 2KEY from users account to address of this contract
     */
    function allocate2KEY(
        address user,
        uint amount
    )
    public
    onlyMaintainer
    {
        uint userBalance = PROXY_STORAGE_CONTRACT.getUint(keccak256(_2KEYBalance, user));
        uint contractBalance = PROXY_STORAGE_CONTRACT.getUint(keccak256(_2KEYBalance, this));
        userBalance -= amount;
        contractBalance += amount;
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_2KEYBalance, user), userBalance);
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_2KEYBalance, this), contractBalance);
    }

    /**
     * @notice      Function that allocates specified amount of USD from users account to address of this contract
     */
    function allocateUSD(
        address user,
        uint amount
    )
    public
    onlyMaintainer
    {
        uint userBalance = PROXY_STORAGE_CONTRACT.getUint(keccak256(_USDBalance, user));
        uint contractBalance = PROXY_STORAGE_CONTRACT.getUint(keccak256(_USDBalance, this));
        userBalance -= amount;
        contractBalance += amount;
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_USDBalance, user), userBalance);
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_USDBalance, this), contractBalance);
    }


}