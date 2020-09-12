pragma solidity ^0.4.24;
//
//import "../upgradability/Upgradeable.sol";
//import "../interfaces/storage-contracts/ITwoKeyPlasmaParticipationRewardsStorage.sol";
//
contract TwoKeyPlasmaParticipationRewards {
//
//    bool initialized;
//    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;
//    ITwoKeyPlasmaParticipationRewardsStorage PROXY_STORAGE_CONTRACT;
//
//
//    string constant _epochIdToAmountOf2KEYTotal= "epochIdToAmountOf2KEYToBeDistributed";
//    string constant _epochIdToAmountOf2KEYDistributed = "epochIdToAmountOf2KEYDistributed";
//    string constant _latestEpochId = "latestEpochId";
//    string constant _addressesToBePaid = "addressesToBePaid";
//    string constant _addressToPendingBalance = "addressToPendingBalance";
//    string constant _addressToPaidBalance = "addressToPaidBalance";
//
//    function setInitialParams(
//        address _twoKeyPlasmaSingletonRegistry,
//        address _proxyStorage
//    )
//    public
//    {
//        require(initialized == false);
//
//        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
//        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaParticipationRewardsStorage(_proxyStorage);
//
//        initialized = true;
//    }
//
//    function registerParticipationMiningEpoch(
//        uint epochId,
//        address [] influencers,
//        uint [] rewards
//    )
//    public
//    onlyMaintainer
//    {
//        uint totalRewards;
//
//
//    }
//
//    /**
//     * @notice          Function to fetch id of latest epoch
//     */
//    function getLatestEpochId()
//    public
//    view
//    returns (uint)
//    {
//        return getUint(keccak256(_latestEpochId));
//    }
//
//    /**
//     * @notice          Function to get amount of 2KEY tokens which have to be distributed in epoch
//     * @param           epochId is the id in the epoch
//     */
//    function getTotalAmountOf2KEYToBeDistributedInEpoch(
//        uint epochId
//    )
//    public
//    view
//    returns (uint)
//    {
//        return getUint(keccak256(_epochIdToAmountOf2KEYTotal, epochId));
//    }
//
//    // Internal wrapper method to manipulate storage contract
//    function setUint(
//        bytes32 key,
//        uint value
//    )
//    internal
//    {
//        PROXY_STORAGE_CONTRACT.setUint(key, value);
//    }
//
//    // Internal wrapper method to manipulate storage contract
//    function getUint(
//        bytes32 key
//    )
//    internal
//    view
//    returns (uint)
//    {
//        return PROXY_STORAGE_CONTRACT.getUint(key);
//    }
//
}
