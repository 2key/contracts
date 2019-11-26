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
        address twoKeyParticipationMiningPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyParticipationMiningPool");
        address twoKeyNetworkGrowthFund = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyNetworkGrowthFund");
        address twoKeyMPSNMiningPool = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyMPSNMiningPool");
        address twoKeyTeamGrowthFund = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).
            getContractProxyAddress("TwoKeyTeamGrowthFund");


        totalSupply_= 600000000000000000000000000; // 600M tokens total minted supply

        balances[twoKeyUpgradableExchange] = totalSupply_.mul(3).div(100);
        emit Transfer(address(this), twoKeyUpgradableExchange, totalSupply_.mul(3).div(100));

        balances[twoKeyParticipationMiningPool] = totalSupply_.mul(20).div(100);
        emit Transfer(address(this), twoKeyParticipationMiningPool, totalSupply_.mul(20).div(100));

        balances[twoKeyNetworkGrowthFund] = totalSupply_.mul(16).div(100);
        emit Transfer(address(this), twoKeyNetworkGrowthFund, totalSupply_.mul(16).div(100));

        balances[twoKeyMPSNMiningPool] = totalSupply_.mul(10).div(100);
        emit Transfer(address(this), twoKeyMPSNMiningPool, totalSupply_.mul(10).div(100));

        balances[twoKeyTeamGrowthFund] = totalSupply_.mul(4).div(100);
        emit Transfer(address(this), twoKeyTeamGrowthFund, totalSupply_.mul(4).div(100));

        balances[twoKeyAdmin] = totalSupply_.mul(47).div(100);
        emit Transfer(address(this), twoKeyAdmin, totalSupply_.mul(47).div(100));
    }


    /// @notice TwoKeyAdmin is available to freeze all transfers on ERC for some period of time
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
