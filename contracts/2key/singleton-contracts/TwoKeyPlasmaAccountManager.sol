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
    string constant _twoKeyPlasmaCampaignsInventory = "TwoKeyPlasmaCampaignsInventory";
    string constant _messageNotes = "signUserDepositTokens";

    // Accounting
    string constant _userToDepositTimestamp = "userToDepositTimestamp"; // deposit timestamps
    string constant _userToDepositAmount = "userToDepositAmount"; // deposit amounts
    string constant _userToDepositCurrency = "userToDepositCurrency"; // deposit currency

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
     * @notice          Modifier which will be used to restrict calls to only PlasmaCampaignsInventory contract
     */
    modifier onlyPlasmaCampaignsInventory {
        address twoKeyPlasmaCampaignsInventory = getAddressFromTwoKeySingletonRegistry(_twoKeyPlasmaCampaignsInventory);
        require(msg.sender == twoKeyPlasmaCampaignsInventory);
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

    /**
     * @notice          Function that adds new deposit data to arrays
     */
    function saveDepositHistory(
        uint amount,
        string currency
    )
    public
    onlyMaintainer
    {
        // Adds a new timestamp to deposit timestamps array
        uint[] memory userTimestamps = PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositTimestamp, msg.sender));
        uint[] memory newUserTimestamps = new uint[](userTimestamps.length + 1);
        // For loop that is getting array from storage
        for(uint i = 0; i < userTimestamps.length; i++){
            newUserTimestamps[i] = userTimestamps[i];
        }
        // Add new element to an array of timestamps
        newUserTimestamps[i] = block.timestamp;
        // Set new array with one more element
        PROXY_STORAGE_CONTRACT.setUintArray(keccak256(_userToDepositTimestamp, msg.sender), newUserTimestamps);

        // Adds a new amount to deposit amounts array
        uint[] memory userAmounts = PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositAmount, msg.sender));
        uint[] memory newUserAmounts = new uint[](userAmounts.length + 1);
        // For loop that is getting array from storage
        for(i = 0; i < userAmounts.length; i++){
            newUserAmounts[i] = userAmounts[i];
        }
        // Add new element to an array of amounts
        newUserAmounts[i] = amount;
        // Set new array with one more element
        PROXY_STORAGE_CONTRACT.setUintArray(keccak256(_userToDepositAmount, msg.sender), newUserAmounts);

        // Adds a new currency to deposit currencies array
        bytes32[] memory userCurrencies = PROXY_STORAGE_CONTRACT.getBytes32Array(keccak256(_userToDepositCurrency, msg.sender));
        bytes32[] memory newUserCurrencies = new bytes32[](userCurrencies.length + 1);
        // For loop that is getting array from storage
        for(i = 0; i < userCurrencies.length; i++){
            newUserCurrencies[i] = userCurrencies[i];
        }
        // Add new element to an array of currencies
        newUserCurrencies[i] = stringToBytes32(currency);
        // Set new array with one more element
        PROXY_STORAGE_CONTRACT.setBytes32Array(keccak256(_userToDepositCurrency, msg.sender), userCurrencies);
    }

    /**
     * @notice          Function that transfers 2KEY from users balance to beneficiary
     * @param           beneficiary is address to which user is sending funds
     * @param           amount is amount of 2KEY tokens
     */
    function transfer2KEY(
        address beneficiary,
        uint amount
    )
    public
    {
        uint userBalance = get2KEYBalance(msg.sender);
        uint beneficiaryBalance = get2KEYBalance(beneficiary);

        // Check if user has enough funds to perform transaction
        require(userBalance >= amount, "no enough tokens");

        // Sets modified users balance -> balance - amount
        setUserBalance2KEY(
            msg.sender,
            userBalance.sub(amount)
        );

        // Sets modified beneficiary balance -> balance + amount
        setUserBalance2KEY(
            beneficiary,
            beneficiaryBalance.add(amount)
        );
    }

    /**
     * @notice          Function that transfers USDT from users balance to beneficiary
     * @param           beneficiary is address to which user is sending funds
     * @param           amount is amount of USDT tokens
     */
    function transferUSDT(
        address beneficiary,
        uint amount
    )
    public
    {
        uint userBalance = getUSDTBalance(msg.sender);
        uint beneficiaryBalance = getUSDTBalance(beneficiary);

        // Check if user has enough funds to perform transaction
        require(userBalance >= amount, "no enough tokens");

        // Sets modified users balance -> balance - amount
        setUserBalanceUSDT(
            msg.sender,
            userBalance.sub(amount)
        );

        // Sets modified beneficiary balance -> balance + amount
        setUserBalanceUSDT(
            beneficiary,
            beneficiaryBalance.add(amount)
        );
    }

    /**
     * @notice    Function that allocates specified amount of 2KEY from users balance to PlasmaCampaignsInventory contract's balance
     */
    function transfer2KEYFrom(
        address user,
        uint amount
    )
    public
    onlyPlasmaCampaignsInventory
    {
        // Get users balance
        uint userBalance = get2KEYBalance(user);
        // Get contract balance
        uint plasmaCampaignsInventoryBalance = get2KEYBalance(msg.sender);

        // Check if user has enough funds to perform this transaction
        require(userBalance > amount);

        setUserBalance2KEY(user, userBalance.sub(amount));
        // msg.sender is always the address of plasma campaigns inventory contract
        setUserBalance2KEY(msg.sender, plasmaCampaignsInventoryBalance.add(amount));
    }

    /**
     * @notice    Function that allocates specified amount of USDT from users balance to PlasmaCampaignsInventory contract's balance
     */
    function transferUSDTFrom(
        address user,
        uint amount
    )
    public
    onlyPlasmaCampaignsInventory
    {
        // Get users balance
        uint userBalance = getUSDTBalance(user);
        // Get contract balance
        uint plasmaCampaignsInventoryBalance = getUSDTBalance(msg.sender);

        // Check if user has enough funds for this action
        require(userBalance > amount);

        setUserBalanceUSDT(user, userBalance.sub(amount));
        // msg.sender is always the address of plasma campaigns inventory contract
        setUserBalanceUSDT(msg.sender, plasmaCampaignsInventoryBalance.add(amount));
    }

    /**
     * @notice         Function that serves for performing a transfer from one user to another
     *
     * @param           user is address of user who's amount is being sent to beneficiary
     * @param           beneficiary is user to which amount is sent to
     * @param           amount is amount of funds being transfered (2KEY)
     */
    function transfer2KEYFromTo(
        address user,
        address beneficiary,
        uint amount
    )
    public
    {
        // Users balance
        uint userBalance = get2KEYBalance(user);
        // Beneficiary balance
        uint beneficiaryBalance = get2KEYBalance(beneficiary);

        // Check if user has enough funds for transaction
        require(userBalance > amount);

        // Set new balances
        setUserBalance2KEY(user, userBalance.sub(amount));
        setUserBalance2KEY(beneficiary, beneficiaryBalance.add(amount));
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
        return (
            // Gets array of users timestamps
            PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositTimestamp, user)),
            // Gets array of users deposit amounts
            PROXY_STORAGE_CONTRACT.getUintArray(keccak256(_userToDepositAmount, user)),
            // Gets array of deposit currencies
            PROXY_STORAGE_CONTRACT.getBytes32Array(keccak256(_userToDepositCurrency, user))
        );
    }
}
