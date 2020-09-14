pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaParticipationRewardsStorage.sol";

contract TwoKeyPlasmaParticipationRewards is Upgradeable {

    bool initialized;
    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
    ITwoKeyPlasmaParticipationRewardsStorage PROXY_STORAGE_CONTRACT;


    string constant _userToTotalAmountPending = "userToTotalAmountPending";
    string constant _userToTotalAmountWithdrawn = "userToTotalAmountWithdrawn";
    string constant _userToSignature = "userToSignature";
    string constant _latestEpochId = "latestEpochId";


    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaParticipationRewardsStorage(_proxyStorage);

        initialized = true;
    }

    function registerParticipationMiningEpoch(
        uint epochId,
        address [] influencers,
        uint [] rewards
    )
    public
    //TODO: add onlyMaintainer flag
    {
        uint totalRewards;


    }

    /**
     * @notice          Function to fetch id of latest epoch
     */
    function getLatestEpochId()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_latestEpochId));
    }


    // Internal wrapper method to manipulate storage contract
    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }

    // Internal wrapper method to manipulate storage contract
    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

}
