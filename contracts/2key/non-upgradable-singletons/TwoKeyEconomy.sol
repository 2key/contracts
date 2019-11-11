pragma solidity 0.4.24;


import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../ERC20/StandardTokenModified.sol";


contract TwoKeyEconomy is StandardTokenModified {
    string public name = 'TwoKeyEconomy';
    string public symbol= '2KEY';
    uint8 public decimals= 18;

    address public twoKeyAdmin;
    address public twoKeySingletonRegistry;

    modifier onlyTwoKeyAdmin {
        require(msg.sender == twoKeyAdmin);
        _;
    }

    constructor (
        address _twoKeySingletonRegistry
    )
    public
    {
        twoKeySingletonRegistry = _twoKeySingletonRegistry;

        twoKeyAdmin = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyAdmin");

        address twoKeyUpgradableExchange = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyUpgradableExchange");
        address twoKeyCommunityTokenPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyCommunityTokenPool");
        address twoKeyLongTermTokenPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyLongTermTokenPool");

        totalSupply_= 600000000000000000000000000; // 600M tokens total minted supply


        // Updating balances
        balances[twoKeyUpgradableExchange] = totalSupply_.mul(3).div(100);
        emit Transfer(address(this), twoKeyUpgradableExchange, totalSupply_.mul(3).div(100));

        balances[twoKeyCommunityTokenPool] = totalSupply_.mul(20).div(100);
        emit Transfer(address(this), twoKeyCommunityTokenPool, totalSupply_.mul(20).div(100));

        balances[twoKeyLongTermTokenPool] = totalSupply_.mul(40).div(100);
        emit Transfer(address(this), twoKeyLongTermTokenPool, totalSupply_.mul(40).div(100));

        balances[twoKeyAdmin] = totalSupply_.mul(37).div(100);
        emit Transfer(address(this), twoKeyAdmin, totalSupply_.mul(37).div(100));
    }


    /// @notice TwoKeyAmin is available to freeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function freezeTransfers()
    public
    onlyTwoKeyAdmin
    {
        transfersFrozen = true;
    }

    /// @notice TwoKeyAmin is available to unfreeze all transfers on ERC for some period of time
    /// @dev in TwoKeyAdmin only Congress can call this
    function unfreezeTransfers()
    public
    onlyTwoKeyAdmin
    {
        transfersFrozen = false;
    }

}
