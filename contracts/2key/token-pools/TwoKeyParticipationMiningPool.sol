pragma solidity ^0.4.24;

import "./TokenPool.sol";
import "../interfaces/ITwoKeyRegistry.sol";
import "../interfaces/storage-contracts/ITwoKeyParticipationMiningPoolStorage.sol";
import "../interfaces/ITwoKeyParticipationPaymentsManager.sol";
import "../libraries/SafeMath.sol";

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
    string constant _epochInsideYear = "epochInsideYear";

    string constant _epochIdToAmountOf2KEYTotal= "epochIdToAmountOf2KEYToBeDistributed";
    string constant _epochIdToAmountOf2KEYDistributed = "epochIdToAmountOf2KEYDistributed";
    string constant _latestEpochId = "latestEpochId";

    string constant _twoKeyParticipationsManager = "TwoKeyParticipationPaymentsManager";

    using SafeMath for *;

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

        uint totalAmountOfTokens = getContractBalance(); //120M WEI's

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

    function registerParticipationMiningEpoch(
        uint epochId,
        uint totalAmount2KEY
    )
    public
    onlyTwoKeyCongress
    {
        // Require that by mistake same epochId can't be submitted twice
        require(epochId > getLatestEpochId());

        // Set total amount which have to be distributed inside epoch
        setUint(
            keccak256(_epochIdToAmountOf2KEYTotal, epochId),
            totalAmount2KEY
        );
    }

    function distributeEpoch(
        uint epochId,
        address [] influencers,
        uint [] rewards
    )
    public
    onlyMaintainer
    {
        // Require that this epoch exists
        require(epochId <= getLatestEpochId());

        uint len = influencers.length;
        uint i;
        uint sum = 0;

        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

        for(i=0; i<len; i++) {
            // Transfer tokens
            IERC20(twoKeyEconomy).transfer(influencers[i], rewards[i]);
            sum = sum.add(rewards[i]);
        }

        bytes32 keyStorage = keccak256(_epochIdToAmountOf2KEYDistributed, epochId);

        uint totalDistributedForEpoch = getUint(keyStorage) + sum;

        require(totalDistributedForEpoch <= getTotalAmountOf2KEYToBeDistributedInEpoch(epochId));

        setUint(
            keyStorage,
            totalDistributedForEpoch
        );
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

    /**
     * @notice          Function to get amount of 2KEY tokens which have to be distributed in epoch
     * @param           epochId is the id in the epoch
     */
    function getTotalAmountOf2KEYToBeDistributedInEpoch(
        uint epochId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_epochIdToAmountOf2KEYTotal, epochId));
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
