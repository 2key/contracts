pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyParticipationMiningPoolStorage.sol";
import "../interfaces/ITwoKeyParticipationPaymentsManager.sol";
import "../interfaces/ITwoKeyEventSource.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";

/**
 * @author Nikola Madjarevic
 * Created at 2/5/19
 */
contract TwoKeyParticipationMiningPool is TokenPool {

    using SafeMath for *;
    using Call for *;

    /**
     * Constant keys for storage contract
     */
    string constant _isAddressWhitelisted = "isAddressWhitelisted";
    string constant _epochInsideYear = "epochInsideYear";
    string constant _isExistingSignature = "isExistingSignature";
    string constant _dateStartingCountingMonths = "dateStartingCountingMonths";

    // Initial amount of tokens is 120M
    uint constant public initialAmountOfTokens = 120 * (1e6) * (1e18);
    // 1M tokens monthly allowance
    uint constant public monthlyTransferAllowance = 1 * (1e6) * (1e18);

    string constant _signatoryAddress = "signatoryAddress";
    string constant _twoKeyParticipationsManager = "TwoKeyParticipationPaymentsManager";

    /**
     * Pointer to it's proxy storage contract
     */
    ITwoKeyParticipationMiningPoolStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Modifier to restrict calls only to TwoKeyAdmin or
     * some of whitelisted addresses inside this contract
     */
    modifier onlyTwoKeyAdminOrWhitelistedAddress {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin || isAddressWhitelisted(msg.sender));
        _;
    }

    modifier onlyTwoKeyCongress {
        address twoKeyCongress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyCongress");
        require(msg.sender == twoKeyCongress);
        _;
    }

    function setInitialParams(
        address twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyParticipationMiningPoolStorage(_proxyStorage);

        initialized = true;
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
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

    function setSignatureIsExisting(
        bytes signature
    )
    internal
    {
        setBool(keccak256(_isExistingSignature,signature), true);
    }

    function isMaintainer(
        address _address
    )
    internal
    view
    returns (bool)
    {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        return ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(_address);
    }


    /**
     * @notice          Function where congress can set signatory address
     *                  and that's the only address eligible to sign the rewards messages
     * @param           signatoryAddress is the address which will be used to sign rewards
     */
    function setSignatoryAddress(
        address signatoryAddress
    )
    public
    onlyTwoKeyCongress
    {
        PROXY_STORAGE_CONTRACT.setAddress(
            keccak256(_signatoryAddress),
            signatoryAddress
        );
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
     * @notice          Function where maintainer can set withdrawal parameters
     * @param           dateStartingCountingMonths is the date (unix timestamp) from which
     *                  the tokens are getting unlocked
     */
    function setWithdrawalParameters(
        uint dateStartingCountingMonths
    )
    public
    onlyMaintainer
    {
        // Require that this function can be called only once
        require(getUint(keccak256(_dateStartingCountingMonths)) == 0);

        // Set date when counting months starts
        setUint(
            keccak256(_dateStartingCountingMonths),
            dateStartingCountingMonths
        );
    }


    /**
     * @notice Function which does transfer with special requirements with annual limit
     * @param amountOfTokens is the amount of tokens sent
     * @dev Only TwoKeyAdmin or Whitelisted address contract can issue this call
     */
    function transferTokensToAddress(
        uint amountOfTokens
    )
    public
    onlyTwoKeyAdminOrWhitelistedAddress
    {
        // Assert that amount of tokens to be withdrawn is less than amount of tokens unlocked
        require(amountOfTokens < getAmountOfTokensUnlockedForWithdrawal(block.timestamp));

        //We're always sending tokens to ParticipationPaymentsManager
        address receiver = getAddressFromTwoKeySingletonRegistry(_twoKeyParticipationsManager);

        // Transfer the tokens
        super.transferTokens(receiver,amountOfTokens);

        //Alert that tokens have been transferred
        ITwoKeyParticipationPaymentsManager(receiver).transferTokensFromParticipationMiningPool(
            amountOfTokens
        );

    }


    /**
     * @notice          Function where user can come with signature taken on plasma and
     *                  withdraw tokens he has earned
     * @param           signature is the signature created by signatory address for withdrawal
     * @param           amountOfTokens is the exact amount of tokens signed inside this signature
     */
    function withdrawTokensWithSignature(
        bytes signature,
        uint amountOfTokens
    )
    public
    {
        // Assert that amount of tokens to be withdrawn is less than amount of tokens unlocked
        require(amountOfTokens < getAmountOfTokensUnlockedForWithdrawal(block.timestamp));

        // recover signer of signature
        address messageSigner = recoverSignature(
            msg.sender,
            amountOfTokens,
            signature
        );

        // Assert that this signature is created by signatory address
        require(getSignatoryAddress() == messageSigner);

        // First check if this signature is used
        require(isExistingSignature(signature) == false);

        // Set that signature is existing and can't be used anymore
        setSignatureIsExisting(signature);

        // Emit event that user have withdrawn his network earnings
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitUserWithdrawnNetworkEarnings(
            msg.sender,
            amountOfTokens
        );

        // Transfer ERC20 tokens from pool to user
        super.transferTokens(msg.sender, amountOfTokens);
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
     * @notice          Function to calculate amount of tokens available to be withdrawn
     *                  at current moment which will take care about monthly allowances
     * @param           timestamp is the timestamp of withdrawal
     */
    function getAmountOfTokensUnlockedForWithdrawal(
        uint timestamp
    )
    public
    view
    returns (uint)
    {
        uint dateStartedCountingMonths = getDateStartingCountingMonths();

        // We do sub here mostly because of underflow
        uint totalTimePassedFromUnlockingDay = timestamp.sub(dateStartedCountingMonths);

        // Calculate total amount of tokens being unlocked by now
        uint totalUnlockedByNow = ((totalTimePassedFromUnlockingDay) / (30 days) + 1) * monthlyTransferAllowance;

        // Get total amount already transferred
        uint totalTokensTransferedByNow = getTotalAmountOfTokensTransfered();

        // Return tokens available at this moment
        return (totalUnlockedByNow.sub(totalTokensTransferedByNow));
    }


    /**
     * @notice          Function where maintainer can check who signed the message
     * @param           userAddress is the address of user for who we signed message
     * @param           amountOfTokens is the amount of pending rewards user wants to claim
     * @param           signature is the signature created by maintainer
     */
    function recoverSignature(
        address userAddress,
        uint amountOfTokens,
        bytes signature
    )
    public
    view
    returns (address)
    {
        // Generate hash
        bytes32 hash = keccak256(
            abi.encodePacked(
                keccak256(abi.encodePacked('bytes binding user rewards')),
                keccak256(abi.encodePacked(userAddress,amountOfTokens))
            )
        );

        // Recover signer message from signature
        return Call.recoverHash(hash,signature,0);
    }


    /**
     * @notice          Function to check if signature is already existing,
                        means that is has been used, and can't be used anymore
     * @param           signature is the signature created by maintainer
     */
    function isExistingSignature(
        bytes signature
    )
    public
    view
    returns (bool)
    {
        return getBool(keccak256(_isExistingSignature,signature));
    }


    /**
     * @notice          Function to get total amount of tokens transfered by now
     */
    function getTotalAmountOfTokensTransfered()
    public
    view
    returns (uint)
    {
        // Sub from initial amount of tokens current balance
        return initialAmountOfTokens.sub(
            IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)).balanceOf(address(this))
        );
    }


    /**
     * @notice          Function to get the first date from which the time started to unlock
     */
    function getDateStartingCountingMonths()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_dateStartingCountingMonths));
    }


    /**
     * @notice          Function to get how many tokens are getting unlocked every month
     */
    function getMonthlyTransferAllowance()
    public
    view
    returns (uint)
    {
        return monthlyTransferAllowance;
    }

    /**
     * @notice          Function to fetch signatory address
     */
    function getSignatoryAddress()
    public
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(keccak256(_signatoryAddress));
    }
}
