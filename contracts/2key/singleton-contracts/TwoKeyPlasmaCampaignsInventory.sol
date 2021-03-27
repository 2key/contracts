pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaCampaignsInventoryStorage.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";

 /**
  * @title TwoKeyPlasmaCampaignsInventory contract
  * @author Marko Lazic
  * Github: markolazic01
  */
contract TwoKeyPlasmaCampaignsInventory is Upgradeable {

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaCampaignsInventoryStorage PROXY_STORAGE_CONTRACT;

    // TODO: contract is not initialized
    // TODO: We create dedicated contract interface with required actions in order to avoid gas
    // TODO: And then initialize it only when you need it by using getAddressFromTwoKeySingletonRegistry function

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaAccountManager = "TwoKeyPlasmaAccountManager";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";

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
     * @notice          Function that allocates specified amount of 2KEY from users balance to this contract's balance
     */
    function addInventory2KEY(
        uint amount,
        uint bountyPerConversionUSD // given value in usd - convert to 2key using exchange rate contract
    )
    public
    {
        //TODO: bountyPerConversionUSD from usd to 2key value
        uint pairValue = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate)).getPairValue("USD/2KEY");
        uint bountyPerConversion2KEY = bountyPerConversionUSD / pairValue;

        //TODO: Check description in plasma campaigns addInventory
        //TODO: bountyPerConversion is the value which will be used later, currently value is the budget amount
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
        .transfer2KEYFrom(msg.sender, amount);
    }

    /**
     * @notice          Function that allocates specified amount of USDT from users balance to this contract's balance
     */
    function addInventoryUSDT(
        uint amount,
        uint bountyPerConversionUSD
    )
    public
    {
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaAccountManager))
        .transferUSDTFrom(msg.sender, amount);
    }

}
