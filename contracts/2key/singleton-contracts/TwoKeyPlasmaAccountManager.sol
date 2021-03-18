pragma solidity ^0.4.24;

import "../upgradability/Upgradeable.sol";
import "../interfaces/storage-contracts/ITwoKeyPlasmaAccountManagerStorage.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../libraries/Call.sol";
import "../libraries/SafeMath.sol";

/**
 * TwoKeyPlasmaAccountManager contract.
 * @author Nikola Madjarevic
 * Github: madjarevicn
 */
contract TwoKeyPlasmaAccountManager is Upgradeable {

    using Call for *;
    using SafeMath for uint;

    bool initialized;

    string constant _twoKeyPlasmaMaintainersRegistry = "TwoKeyPlasmaMaintainersRegistry";
    string constant _messageNotes = "signUserDepositTokens";

    // Accounting
    string constant _userToDepositTimestamp = "userToDepositTimestamp"; // deposit timestamps
    string constant _userToDepositAmount = "userToDepositAmount"; // deposit amounts
    string constant _userToDepositCurrency = "userToDepositCurrency"; // deposit currency

    /**
     * Example:
        depositsTimestamps = [12319391931,12319391931,12319391931]
        deposits = [500000000000000000000,1500000000000000000000,34500000000000000000000]
        Always length of those 2 arrays has to be same
     */

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

    /**
     * @notice          Function that converts string to bytes32
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result){
        bytes memory tempEmptyStringTest = bytes(source);
        if(tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice          Function to get address from TwoKeyPlasmaSingletonRegistry
     *
     * @param           contractName is the name of the contract
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_PLASMA_SINGLETON_REGISTRY)
        .getContractProxyAddress(contractName);
    }

    /**
     * @notice          Function to return who signed msg
     * @param           userAddress is the address of user for who we signed message
     * @param           tokenAddress is the token in which user is doing deposit
     * @param           amountOfTokens is the amount of tokens being deposited
     * @param           signature is the signature created by maintainer
     */
    function recoverSignature(
        address userAddress,
        address tokenAddress,
        uint amountOfTokens,
        bytes signature
    )
    internal
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked(_messageNotes)),
                keccak256(abi.encodePacked(userAddress, amountOfTokens, tokenAddress))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }

    /**
     * @notice          Internal function to set user balances in 2KEY
     * @param           user is the address of the user for whom we're allocating the funds
     * @param           amount is the amount of the tokens user has
     */
    function setUserBalance2KEY(
        address user,
        uint amount
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_userTo2KEYBalance, user), amount);
    }

    /**
     * @notice          Internal function to set user balances in USDT
     * @param           user is the address of the user for whom we're allocating the funds
     * @param           amount is the amount of the tokens user has
     */
    function setUserBalanceUSDT(
        address user,
        uint amount
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_userToUSDTBalance, user), amount);
    }

    /**
     * @notice          Function to add balance in USDT for a user
     * @param           beneficiary is user address
     * @param           amount is the amount of the tokens user deposited
     * @param           signature is message signed by signatory address proofing the deposit was verified
     */
    function addBalanceUSDT(
        address beneficiary,
        uint amount,
        bytes signature
    )
    public
    onlyMaintainer
    {
        //TODO: Verify signature
        uint userBalance = getUSDTBalance(beneficiary);

        // Allocate more funds for user
        setUserBalanceUSDT(
            beneficiary,
            userBalance.add(amount)
        );

        saveDepositHistory(amount ,"USDT");
    }

    /**
     * @notice          Function to add balance in 2KEY for a user
     * @param           beneficiary is user address
     * @param           amount is the amount of the tokens user deposited
     * @param           signature is message signed by signatory address proofing the deposit was verified
     */
    function addBalance2KEY(
        address beneficiary,
        uint amount,
        bytes signature
    )
    public
    onlyMaintainer
    {
        //TODO: Verify signature
        uint userBalance = get2KEYBalance(beneficiary);

        setUserBalance2KEY(
            beneficiary,
            userBalance.add(amount)
        );

        saveDepositHistory(amount, "2KEY");
    }

    function saveDepositHistory(
        uint amount,
        string currency
    )
    public
    onlyMaintainer
    {
        uint[] memory userTimestamps = PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositTimestamp, msg.sender));
        uint[] memory newUserTimestamps = new uint[](userTimestamps.length + 1);
        for(uint i = 0; i < userTimestamps.length; i++){
            newUserTimestamps[i] = userTimestamps[i];
        }
        newUserTimestamps[i] = block.timestamp;
        PROXY_STORAGE_CONTRACT.setUintArray(keccak256(_userToDepositTimestamp, msg.sender), newUserTimestamps);

        uint[] memory userAmounts = PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositAmount, msg.sender));
        uint[] memory newUserAmounts = new uint[](userAmounts.length + 1);
        for(i = 0; i < userAmounts.length; i++){
            newUserAmounts[i] = userAmounts[i];
        }
        newUserAmounts[i] = amount;
        PROXY_STORAGE_CONTRACT.setUintArray(keccak256(_userToDepositAmount, msg.sender), newUserAmounts);

        bytes32[] memory userCurrencies = PROXY_STORAGE_CONTRACT.getBytes32Array(keccak256(_userToDepositCurrency, msg.sender));
        bytes32[] memory newUserCurrencies = new bytes32[](userCurrencies.length + 1);
        for(i = 0; i < userCurrencies.length; i++){
            newUserCurrencies[i] = userCurrencies[i];
        }
        newUserCurrencies[i] = stringToBytes32(currency);
        PROXY_STORAGE_CONTRACT.setBytes32Array(keccak256(_userToDepositCurrency, msg.sender), userCurrencies);
    }

    function transfer2KEY(
        address beneficiary,
        uint amount
    )
    public
    {
        uint userBalance = get2KEYBalance(msg.sender);
        uint beneficiaryBalance = get2KEYBalance(beneficiary);

        require(userBalance >= amount, "no enough tokens");

        setUserBalance2KEY(
            msg.sender,
            userBalance.sub(amount)
        );

        setUserBalance2KEY(
            beneficiary,
            beneficiaryBalance.add(amount)
        );
    }

    function transferUSD(
        address beneficiary,
        uint amount
    )
    public
    {
        uint userBalance = getUSDTBalance(msg.sender);
        uint beneficiaryBalance = getUSDTBalance(beneficiary);

        require(userBalance >= amount, "no enough tokens");

        setUserBalanceUSDT(
            msg.sender,
            userBalance.sub(amount)
        );

        setUserBalanceUSDT(
            beneficiary,
            beneficiaryBalance.add(amount)
        );
    }

    /**
     * @notice          Function to get balances of user in 2KEY
     */
    function get2KEYBalance(address user)
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_userTo2KEYBalance, user));
    }

    /**
     * @notice          Function to get balances of user in USDT
     */
    function getUSDTBalance(address user)
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_userToUSDTBalance, user));
    }

    /**
     * @notice          Function to get denomination of USDT
     */
    function getUSDTDecimals()
    public
    view
    returns (uint)
    {
        return 6;
    }

    /**
     * @notice          Function to get denomination of 2KEY
     */
    function get2KEYDecimals()
    public
    view
    returns (uint)
    {
        return 18;
    }

    //TODO: Add following getters:
    //TODO: Get method to get info about user deposits based on input currency

    /**
     * @notice          Function that returns users deposit history details
     */
    function getUserDepositsHistory(
        address user
    )
    public
    view
    returns (
        uint [],
        uint [],
        bytes32 []
    )
    {
        //TODO Use existing fucntion stringToBytes32 when converting from currency string to bytes32
        return (
            PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositTimestamp, user)),
            PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositAmount, user)),
            PROXY_STORAGE_CONTRACT.getBytes32Array(keccak256(_userToDepositCurrency, user))
        );
    }
}
