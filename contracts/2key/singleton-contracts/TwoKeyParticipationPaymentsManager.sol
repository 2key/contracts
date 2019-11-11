pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyParticipationPaymentsManagerStorage.sol";
import "../interfaces/ITwoKeyRegistry.sol";


contract TwoKeyParticipationPaymentsManager is Upgradeable, ITwoKeySingletonUtils {

    ITwoKeyParticipationPaymentsManagerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _twoKeyParticipationPaymentsManagerStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyParticipationPaymentsManagerStorage(_twoKeyParticipationPaymentsManagerStorage);

        initialized = true;
    }


    modifier onlyTwoKeyParticipationMiningPool {
        address participationMiningPool = getAddressFromTwoKeySingletonRegistry("TwoKeyParticipationMiningPool");
        require(msg.sender == participationMiningPool);
        _;
    }

    /**
     * @notice Function to validate if the user is properly registered in TwoKeyRegistry
     * @param _receiver is the address we want to send tokens to
     */
    function validateRegistrationOfReceiver(
        address _receiver
    )
    internal
    view
    returns (bool)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry");
        return ITwoKeyRegistry(twoKeyRegistry).checkIfUserExists(_receiver);
    }

    function transferTokensFromParticipationMiningPool(
        uint amountOfTokens,
        uint year,
        uint epoch
    )
    public
    onlyTwoKeyParticipationMiningPool
    {
        // Store that this contract received this tokens from Mining Pool
        bytes32 keyHashForTransfer = keccak256("receivedTokens",year,epoch);
        PROXY_STORAGE_CONTRACT.setUint(keyHashForTransfer, amountOfTokens);
    }
}
