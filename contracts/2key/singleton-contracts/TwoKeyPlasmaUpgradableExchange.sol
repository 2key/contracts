pragma solidity ^0.4.24;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeyPlasmaExchangeRate.sol";
import "../interfaces/ITwoKeyPlasmaAccountManager.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaUpgradableExchangeStorage.sol";

import "../libraries/SafeMath.sol";

import "../upgradability/Upgradeable.sol";

/**
 * @title TwoKeyPlasmaUpgradableExchange contract
 * @author Marko Lazic
 * Github: markolazic01
 */

contract TwoKeyPlasmaUpgradableExchange is Upgradeable{

    using SafeMath for uint;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaUpgradableExchangeStorage PROXY_STORAGE_CONTRACT;

    bool initialized;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _twoKeyPlasmaExchangeRate = "TwoKeyPlasmaExchangeRate";

    /**
     * @notice      Function for contract initialization
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaUpgradableExchangeStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice      Modifier which will be used to restrict set function calls to maintainers only
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }

    /**
     * @notice      Modifier which will restrict function calls to only PlasmaCampaignsInventory contract
     */
    modifier onlyPlasmaCampaignsInventory {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaCampaignsInventory"));
        _;
    }

    /**
     * @notice      Function for getting contract address by name from registry
     *
     * @param       contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY).getContractProxyAddress(contractName);
    }

    /**
     * @notice      Function for getting current 2KEY-USD rate
     */
    function sellRate2Key(
        uint amountToReceive
    )
    internal
    view
    returns (uint)
    {
        uint rate2Key = ITwoKeyPlasmaExchangeRate(getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaExchangeRate))
            .getPairValue("2KEY-USD");
        return amountToReceive.mul(rate2Key).div(10**18);
    }

    /**
     * @notice      Function used to return funds left after rebalancing
     * @param       amountOfTokensToReturn is amount of funds left
     */
    function returnTokensBackToExchange(
        uint amountOfTokensToReturn
    )
    public
    onlyPlasmaCampaignsInventory
    {
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaAccountManager"))
        .transfer2KEYFromTo(
            msg.sender,
            address(this),
            amountOfTokensToReturn
        );
    }

    /**
     * @notice      Function used to get more funds for rebalancing
     * @param       amountOfTokensRequested is amount of funds which has been requested
     */
    function getMore2KeyTokensForRebalancing(
        uint amountOfTokensRequested
    )
    public
    onlyPlasmaCampaignsInventory
    {
        ITwoKeyPlasmaAccountManager(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaAccountManager"))
            .transfer2KEY(msg.sender, amountOfTokensRequested);
    }
}