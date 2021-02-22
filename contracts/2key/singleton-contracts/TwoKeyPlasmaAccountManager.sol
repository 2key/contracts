pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaAccountManagerStorage.sol";

/**
 * TwoKeyPlasmaAccountManager contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyPlasmaAccountManager is Upgradeable {
    bool initialized;

    string constant _userToUSDTBalance = "userToUSDTBalance";
    string constant _userTo2KEYBalance = "userTo2KEYBalance";

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    ITwoKeyPlasmaAccountManagerStorage PROXY_STORAGE_CONTRACT;

    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaAccountManagerStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice          Modifier which will be used to restrict calls to only maintainers
     */
    modifier onlyMaintainer {
        address twoKeyPlasmaMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaMaintainersRegistry);
        require(ITwoKeyMaintainersRegistry(twoKeyPlasmaMaintainersRegistry).checkIsAddressMaintainer(msg.sender) == true);
        _;
    }


    function addBalanceUSDT(address beneficiary, uint amount, bytes signature) public onlyMaintainer;
    function addBalance2KEY(address beneficiary, uint amount, bytes signature) public onlyMaintainer;

    function get2KEYBalance(address user)
    public
    view
    returns (uint);

    function getUSDTBalance(address user)
    public
    view
    returns (uint);

    function getUSDTDecimals()
    public
    view
    returns (uint)
    {
        return 6;
    }

    function get2KEYDecimals()
    public
    view
    returns (uint)
    {
        return 18;
    }

}
