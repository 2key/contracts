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
    string constant _totalAmount2keys = "totalAmount2keys";
    string constant _annualTransferAmountLimit = "annualTransferAmountLimit";
    string constant _startingDate = "startingDate";
    string constant _yearToStartingDate = "yearToStartingDate";
    string constant _yearToTransferedThisYear = "yearToTransferedThisYear";
    string constant _isAddressWhitelisted = "isAddressWhitelisted";
    string constant _epochInsideYear = "epochInsideYear";
    string constant _isExistingSignature = "isExistingSignature";
    string constant _userToSignatureToAmountWithdrawn = "userToSignatureToAmountWithdrawn";


    string constant _monthlyTransferAllowance = "monthlyTransferAllowance";
    string constant _dateStartingCountingMonths = "dateStartingCountingMonths";
    string constant _totalTokensTransferedByNow = "totalTokensTransferedByNow";

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

        uint totalAmountOfTokens = getContractBalance(); //120M 2KEY's

        setUint(keccak256(_totalAmount2keys), totalAmountOfTokens);
        setUint(keccak256(_annualTransferAmountLimit), totalAmountOfTokens.div(10));
        setUint(keccak256(_startingDate), block.timestamp);

        for(uint i=1; i<=10; i++) {
            bytes32 key1 = keccak256(_yearToStartingDate, i);
            bytes32 key2 = keccak256(_yearToTransferedThisYear, i);

            PROXY_STORAGE_CONTRACT.setUint(keccak256(key1), block.timestamp + i*(1 years));
            PROXY_STORAGE_CONTRACT.setUint(keccak256(key2), 0);
        }

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
     * @notice          Internal function to set the amount user has withdrawn
                        using specific signature
     * @param           user is the address of user
     * @param           signature is the signature created by user
     * @param           amountWithdrawn is the amount user withdrawn using that signature
     */
    function setAmountWithdrawnWithSignature(
        address user,
        bytes signature,
        uint amountWithdrawn
    )
    internal
    {
        setUint(
            keccak256(_userToSignatureToAmountWithdrawn, user, signature),
            amountWithdrawn
        );
    }

    function increaseTransferedAmountFromContract(
        uint amountTransfered
    )
    internal
    {
        uint currentlyTransfered = getTotalAmountOfTokensTransfered();

        setUint(
            keccak256(_totalTokensTransferedByNow),
            currentlyTransfered.add(amountTransfered)
        );
    }


    /**
     * @notice Function which does transfer with special requirements with annual limit
     * @param _amount is the amount of tokens sent
     * @dev Only TwoKeyAdmin or Whitelisted address contract can issue this call
     */
    function transferTokensToAddress(
        uint _amount
    )
    public
    onlyTwoKeyAdminOrWhitelistedAddress
    {
        require(_amount > 0);
        uint year = checkInWhichYearIsTheTransfer();

        bytes32 keyTransferedThisYear = keccak256(_yearToTransferedThisYear,year);
        bytes32 keyAnnualTransferAmountLimit = keccak256(_annualTransferAmountLimit);
        bytes32 keyHashEpochThisYear = keccak256(_epochInsideYear, year);

        //Take the amount transfered this year
        uint transferedThisYear = PROXY_STORAGE_CONTRACT.getUint(keccak256(keyTransferedThisYear));

        //In case there are <= than 10 years, than we have limits for transfer
        if(year <= 10) {
            //Take the annual transfer amount limit
            uint annualTransferAmountLimit = PROXY_STORAGE_CONTRACT.getUint(keccak256(keyAnnualTransferAmountLimit));

            //Check that this transfer will not overflow the annual limit
            require(transferedThisYear.add(_amount) <= annualTransferAmountLimit);
        }

        //Take the epoch for this year ==> which time this year we're calling this function
        uint epochThisYear = PROXY_STORAGE_CONTRACT.getUint(keccak256(keyHashEpochThisYear));

        //We're always sending tokens to ParticipationPaymentsManager
        address receiver = getAddressFromTwoKeySingletonRegistry(_twoKeyParticipationsManager);

        // Transfer the tokens
        super.transferTokens(receiver,_amount);
        //Alert that tokens have been transfered
        ITwoKeyParticipationPaymentsManager(receiver).transferTokensFromParticipationMiningPool(
            _amount,
            year,
            epochThisYear
        );

        // Increase annual epoch
        PROXY_STORAGE_CONTRACT.setUint(keccak256(keyHashEpochThisYear), epochThisYear.add(1));

        // Increase the amount transfered this year
        PROXY_STORAGE_CONTRACT.setUint(keccak256(keyTransferedThisYear), transferedThisYear.add(_amount));
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

    function setWithdrawalParameters(
        uint dateStartingCountingMonths
    )
    public
    onlyMaintainer
    {
        // Require that this function can be called only once
        require(getUint(keccak256(_dateStartingCountingMonths)) == 0);

        // Get annual transfer limit
        uint annualTransferLimit = getUint(keccak256(_annualTransferAmountLimit));

        // Set date when counting months starts
        setUint(
            keccak256(_dateStartingCountingMonths),
            dateStartingCountingMonths
        );

        // Set monthly transfer allowance
        setUint(
            keccak256(_monthlyTransferAllowance),
            annualTransferLimit.div(12)
        );
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
        uint startingDate = getUint(keccak256(_startingDate));

        if(block.timestamp > startingDate && block.timestamp < startingDate + 1 years) {
            return 1;
        } else {
            uint counter = 1;
            uint start = startingDate.add(1 years); //means we're checking for the second year
            while(block.timestamp > start) {
                start = start.add(1 years);
                counter ++;
            }
            return counter;
        }
    }


    /**
     * @notice          Function where user can come with signature taken on plasma and
     *                  withdraw tokens he has earned
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

        // Increase total tokens transfered from contract
        increaseTransferedAmountFromContract(amountOfTokens);

        // Set that signature is existing and can't be used anymore
        setSignatureIsExisting(signature);

        // Set the amount of tokens withdrawn by user using this signature
        setAmountWithdrawnWithSignature(msg.sender, signature, amountOfTokens);

        // Emit event that user have withdrawn his network earnings
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitUserWithdrawnNetworkEarnings(
            msg.sender,
            amountOfTokens
        );

        // Transfer ERC20 tokens from pool to user
        super.transferTokens(msg.sender, amountOfTokens);
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
        uint totalTimePassedFromUnlockingDay = block.timestamp.sub(dateStartedCountingMonths);

        // Get amount of tokens unlocked monthly
        uint monthlyTransferAllowance = getMonthlyTransferAllowance();

        // Calculate total amount of tokens being unlocked by now
        uint totalUnlockedByNow = ((totalTimePassedFromUnlockingDay) / (30 days) + 1) * monthlyTransferAllowance;

        // Get total amount already transfered
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
     * @notice          Function to check amount user has withdrawn using specific signature
     * @param           user is the address of the user
     * @param           signature is the signature signed by maintainer
     */
    function getAmountUserWithdrawnUsingSignature(
        address user,
        bytes signature
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_userToSignatureToAmountWithdrawn, user, signature)
        );
    }

    /**
     * @notice          Function to get total amount of tokens transfered by now
     */
    function getTotalAmountOfTokensTransfered()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_totalTokensTransferedByNow));
    }

    function getDateStartingCountingMonths()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_dateStartingCountingMonths));
    }

    function getMonthlyTransferAllowance()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_monthlyTransferAllowance));
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
