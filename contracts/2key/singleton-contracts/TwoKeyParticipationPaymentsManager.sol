pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../non-upgradable-singletons/ITwoKeySingletonUtils.sol";
import "../interfaces/storage-contracts/ITwoKeyParticipationPaymentsManagerStorage.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/IERC20.sol";


contract TwoKeyParticipationPaymentsManager is Upgradeable, ITwoKeySingletonUtils {

    string constant _receivedTokens = "receivedTokens";
    string constant _isAddressWhitelisted = "isAddressWhitelisted";

    string constant _twoKeyParticipationMiningPool = "TwoKeyParticipationMiningPool";
    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _twoKeyRegistry = "TwoKeyRegistry";
    string constant _twoKeyEconomy = "TwoKeyEconomy";


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
        address participationMiningPool = getAddressFromTwoKeySingletonRegistry(_twoKeyParticipationMiningPool);
        require(msg.sender == participationMiningPool);
        _;
    }

    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin);
        _;
    }

    /**
     * @notice Modifier to restrict calls only to TwoKeyAdmin or
     * some of whitelisted addresses inside this contract
     */
    modifier onlyTwoKeyAdminOrWhitelistedAddress {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin || isAddressWhitelisted(msg.sender));
        _;
    }

    /**
     * @notice Function which can only be called by TwoKeyAdmin contract
     * to add new whitelisted addresses to the contract. Whitelisted address
     * can send tokens out of this contract
     * @param _newWhitelistedAddress is the new whitelisted address we want to add
     */
    function addWhitelistedAddress(
        address _newWhitelistedAddress
    )
    public
    onlyTwoKeyAdmin
    {
        bytes32 keyHash = keccak256(_isAddressWhitelisted,_newWhitelistedAddress);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, true);
    }

    /**
     * @notice Function which can only be called by TwoKeyAdmin contract
     * to remove any whitelisted address from the contract.
     * @param _addressToBeRemovedFromWhitelist is the new whitelisted address we want to remove
     */
    function removeWhitelistedAddress(
        address _addressToBeRemovedFromWhitelist
    )
    public
    onlyTwoKeyAdmin
    {
        bytes32 keyHash = keccak256(_isAddressWhitelisted, _addressToBeRemovedFromWhitelist);
        PROXY_STORAGE_CONTRACT.setBool(keyHash, false);
    }

    /**
     * @notice Function to check if the selected address is whitelisted
     * @param _address is the address we want to get this information
     * @return result of address being whitelisted
     */
    function isAddressWhitelisted(
        address _address
    )
    public
    view
    returns (bool)
    {
        bytes32 keyHash = keccak256(_isAddressWhitelisted, _address);
        return PROXY_STORAGE_CONTRACT.getBool(keyHash);
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
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry);
        return ITwoKeyRegistry(twoKeyRegistry).checkIfUserExists(_receiver);
    }

    function transferTokensFromParticipationMiningPool(
        uint amountOfTokens
    )
    public
    onlyTwoKeyParticipationMiningPool
    {

        bytes32 keyHash = keccak256(_receivedTokens);

        PROXY_STORAGE_CONTRACT.setUint(
            keyHash,
            amountOfTokens + PROXY_STORAGE_CONTRACT.getUint(keyHash)
        );
    }

    /**
     * @notice Function to transfer tokens from contract
     * @param _beneficiary is the receiver address
     * @param _amount is the tokens amount we're transferring
     */
    function transferTokensFromContract(
        address _beneficiary,
        uint _amount
    )
    public
    onlyTwoKeyAdminOrWhitelistedAddress
    {
        require(validateRegistrationOfReceiver(_beneficiary) == true);
        address twoKeyEconomy = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(_twoKeyEconomy);
        IERC20(twoKeyEconomy).transfer(_beneficiary, _amount);
    }

    /**
     * @notice          Function to get amount of tokens received from participation mining pool
     */
    function getAmountOfTokensReceivedFromParticipationMiningPool()
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_receivedTokens));
    }
}
