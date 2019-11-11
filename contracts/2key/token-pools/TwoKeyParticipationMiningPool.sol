pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyParticipationMiningPoolStorage.sol";
/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyParticipationMiningPool is TokenPool {

    /**
     * Constant keys for storage contract
     */
    string constant _totalAmount2keys = "totalAmount2keys";
    string constant _annualTransferAmountLimit = "annualTransferAmountLimit";
    string constant _startingDate = "startingDate";
    string constant _yearToStartingDate = "yearToStartingDate";
    string constant _yearToTransferedThisYear = "yearToTransferedThisYear";
    string constant _isAddressWhitelisted = "isAddressWhitelisted";


    ITwoKeyParticipationMiningPoolStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Modifier to restrict calls only to TwoKeyAdmin or
     * some of whitelisted addresses inside this contract
     */
    modifier onlyTwoKeyAdminOrWhitelistedAddress {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == twoKeyAdmin || isAddressWhitelisted(msg.sender));
        _;
    }

    function setInitialParams(
        address twoKeySingletonesRegistry,
        address _twoKeyEconomy,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        setInitialParameters(_twoKeyEconomy, TWO_KEY_SINGLETON_REGISTRY);

        PROXY_STORAGE_CONTRACT = ITwoKeyParticipationMiningPoolStorage(_proxyStorage);

        //TODO: BUG wrong values in WEI
        setUint(_totalAmount2keys, (120000000) * (10**18));
        setUint(_annualTransferAmountLimit, 20000000);
        setUint(_startingDate, block.timestamp);

        for(uint i=1; i<=10; i++) {
            bytes32 key1 = keccak256(_yearToStartingDate, i);
            bytes32 key2 = keccak256(_yearToTransferedThisYear, i);

            PROXY_STORAGE_CONTRACT.setUint(key1, block.timestamp + i*(1 years));
            PROXY_STORAGE_CONTRACT.setUint(key2, 0);
        }

        initialized = true;
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

    /**
     * @notice Function which does transfer with special requirements with annual limit
     * @param _receiver is the receiver of the tokens
     * @param _amount is the amount of tokens sent
     * @dev Only TwoKeyAdmin or Whitelisted address contract can issue this call
     */
    function transferTokensToAddress(
        address _receiver,
        uint _amount
    )
    public
    onlyTwoKeyAdminOrWhitelistedAddress
    {
        require(validateRegistrationOfReceiver(_receiver) == true);
        require(_amount > 0);

        uint year = checkInWhichYearIsTheTransfer();
        require(year >= 1 && year <= 10);

        bytes32 keyTransferedThisYear = keccak256(_yearToTransferedThisYear,year);
        bytes32 keyAnnualTransferAmountLimit = keccak256(_annualTransferAmountLimit);

        uint transferedThisYear = PROXY_STORAGE_CONTRACT.getUint(keyTransferedThisYear);
        uint annualTransferAmountLimit = PROXY_STORAGE_CONTRACT.getUint(keyAnnualTransferAmountLimit);

        require(transferedThisYear + _amount <= annualTransferAmountLimit);
        super.transferTokens(_receiver,_amount);

        PROXY_STORAGE_CONTRACT.setUint(keyTransferedThisYear, transferedThisYear + _amount);
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
     * @notice Function to check in which year is transfer happening
     * returns year
     */
    function checkInWhichYearIsTheTransfer()
    public
    view
    returns (uint)
    {
        uint startingDate = getUint(_startingDate);

        if(block.timestamp > startingDate && block.timestamp < startingDate + 1 years) {
            return 1;
        } else {
            uint counter = 1;
            uint start = startingDate + 1 years; //means we're checking for the second year
            while(block.timestamp > start || counter == 10) {
                start = start + 1 years;
                counter ++;
            }
            return counter;
        }
    }


    // Internal wrapper method to manipulate storage contract
    function setUint(
        string key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(keccak256(key), value);
    }

    // Internal wrapper method to manipulate storage contract
    function getUint(
        string key
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(key));
    }
}
