pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/storage-contracts/ITwoKeyMPSNMiningPoolStorage.sol";
import "../interfaces/ITwoKeyAdmin.sol";

contract TwoKeyMPSNMiningPool is TokenPool {

    string constant _isAddressWhitelisted = "isAddressWhitelisted";

    ITwoKeyMPSNMiningPoolStorage public PROXY_STORAGE_CONTRACT;


    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyMPSNMiningPoolStorage(_proxyStorage);

        initialized = true;
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
     * @notice Function to transfer tokens from this contract
     * can be done only by TwoKeyAdmin or whitelisted address
     * once rewards release date has passed
     * @param _receiver is the address of tokens receiver
     * @param _amount is the amount of tokens we want to transfer
     */
    function transferTokensFromContract(
        address _receiver,
        uint _amount
    )
    onlyTwoKeyAdminOrWhitelistedAddress
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(ITwoKeyAdmin(twoKeyAdmin).getTwoKeyRewardsReleaseDate() <= block.timestamp);
        super.transferTokens(_receiver,_amount);
    }





}
