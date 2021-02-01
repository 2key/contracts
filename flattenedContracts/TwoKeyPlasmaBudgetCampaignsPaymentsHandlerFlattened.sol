pragma solidity ^0.4.13;

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyPlasmaCampaign {

    function markReferrerReceivedPaymentForThisCampaign(
        address _referrer
    )
    public;

    function computeAndSetRebalancingRatioForReferrer(
        address _referrer,
        uint _currentRate2KEY
    )
    public
    returns (uint,uint);

    function getActiveInfluencers(
        uint start,
        uint end
    )
    public
    view
    returns (address[]);

    function getReferrerPlasmaBalance(
        address _referrer
    )
    public
    view
    returns (uint);
}

contract ITwoKeyPlasmaEventSource {
    function emitPlasma2EthereumEvent(address _plasma, address _ethereum) public;

    function emitPlasma2HandleEvent(address _plasma, string _handle) public;

    function emitCPCCampaignCreatedEvent(address proxyCPCCampaignPlasma, address contractorPlasma) public;

    function emitConversionCreatedEvent(address campaignAddressPublic, uint conversionID, address contractor, address converter) public;

    function emitConversionExecutedEvent(uint conversionID) public;

    function emitConversionRejectedEvent(uint conversionID, uint statusCode) public;

    function emitCPCCampaignMirrored(address proxyAddressPlasma, address proxyAddressPublic) public;

    function emitHandleChangedEvent(address _userPlasmaAddress, string _newHandle) public;

    function emitConversionPaidEvent(uint conversionID) public;

    function emitAddedPendingRewards(address campaignPlasma, address influencer, uint amountOfTokens) public;

    function emitRewardsAssignedToUserInParticipationMiningEpoch(uint epochId, address user, uint reward2KeyWei) public;

    function emitEpochDeclared(uint epochId, uint totalRewardsInEpoch) public;

    function emitEpochRegistered(uint epochId, uint numberOfUsers) public;

    function emitEpochFinalized(uint epochId) public;

    function emitPaidPendingRewards(
        address influencer,
        uint amountNonRebalancedReferrerEarned,
        uint amountPaid,
        address[] campaignsPaid,
        uint [] earningsPerCampaign,
        uint feePerReferrer2KEY
    ) public;

}

contract ITwoKeyPlasmaFactory {
    function isCampaignCreatedThroughFactory(address _campaignAddress) public view returns (bool);
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage is IStructuredStorage {

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyPlasmaBudgetCampaignsPaymentsHandler is Upgradeable {

    using SafeMath for *;

    bool initialized;

    address public TWO_KEY_PLASMA_SINGLETON_REGISTRY;

    string constant _numberOfCycles = "numberOfCycles";

    // Mapping cycle id to total non rebalanced amount payment
    string constant _distributionCycle2TotalNonRebalancedPayment = "distributionCycle2TotalNonRebalancedPayment";

    // Mapping cycle id to total rebalanced amount payment
    string constant _distributionCycleToTotalRebalancedPayment = "distributionCycleToTotalRebalancedPayment";

    // Mapping distribution cycle to referrers being paid in that cycle
    string constant _distributionCycleIdToReferrersPaid = "distributionCycleIdToReferrersPaid";

    // Mapping referrer to all campaigns he participated at and are having pending distribution
    string constant _referrer2pendingCampaignAddresses = "referrer2pendingCampaignAddresses";

    // Mapping referrer to all campaigns that are in progress of distribution
    string constant _referrer2inProgressCampaignAddress = "referrer2inProgressCampaignAddress";

    // Mapping referrer to all campaigns he already received a payment
    string constant _referrer2finishedAndPaidCampaigns = "referrer2finishedAndPaidCampaigns";

    // Mapping referrer to how much rebalanced amount he has pending
    string constant _referrer2cycleId2rebalancedAmount = "referrer2cycleId2rebalancedAmount";

    // Mapping referrer to how much non rebalanced he earned in the cycle
    string constant _referrer2cycleId2nonRebalancedAmount = "referrer2cycleId2nonRebalancedAmount";

    ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice          Modifier which will be used to restrict calls to only maintainers
     */
    modifier onlyMaintainer {
        require(
            ITwoKeyMaintainersRegistry(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaMaintainersRegistry"))
            .checkIsAddressMaintainer(msg.sender) == true
        );
        _;
    }

    /**
     * @notice          Modifier restricting access to the function only to campaigns
     *                  created using TwoKeyPlasmaFactory contract
     */
    modifier onlyBudgetCampaigns {
        require(
            ITwoKeyPlasmaFactory(getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaFactory"))
            .isCampaignCreatedThroughFactory(msg.sender)
        );
        _;
    }


    function setInitialParams(
        address _twoKeyPlasmaSingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_PLASMA_SINGLETON_REGISTRY = _twoKeyPlasmaSingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * ------------------------------------------------
     *        Internal getters and setters
     * ------------------------------------------------
     */


    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key,value);
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

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }

    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key,value);
    }


    function getAddressArray(
        bytes32 key
    )
    internal
    view
    returns (address [])
    {
        return PROXY_STORAGE_CONTRACT.getAddressArray(key);
    }


    function setAddressArray(
        bytes32 key,
        address [] addresses
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddressArray(key, addresses);
    }


    function copyAddressArray(
        bytes32 keyArrayToCopy,
        bytes32 keyArrayToStore
    )
    internal
    {
        address [] memory arrayToCopy = getAddressArray(keyArrayToCopy);
        PROXY_STORAGE_CONTRACT.setAddressArray(
            keyArrayToStore,
            arrayToCopy
        );
    }


    function appendToArray(
        bytes32 keyBaseArray,
        bytes32 keyArrayToAppend
    )
    internal
    {
        address [] memory baseArray = getAddressArray(keyBaseArray);
        address [] memory arrayToAppend = getAddressArray(keyArrayToAppend);

        uint len = baseArray.length + arrayToAppend.length;

        address [] memory newBaseArray = new address[](len);

        uint i;
        uint j;

        // Copy base array
        for(i=0; i< baseArray.length; i++) {
            newBaseArray[i] = baseArray[i];
        }

        // Copy array to append
        for(i=baseArray.length; i<len; i++) {
            newBaseArray[i] = arrayToAppend[j];
            j++;
        }

        setAddressArray(keyBaseArray, newBaseArray);
    }



    function pushAddressToArray(
        bytes32 key,
        address value
    )
    internal
    {
        address[] memory currentArray = PROXY_STORAGE_CONTRACT.getAddressArray(key);

        uint newLength = currentArray.length + 1;

        address [] memory newArray = new address[](newLength);

        uint i;

        for(i=0; i<newLength - 1; i++) {
            newArray[i] = currentArray[i];
        }

        // Append the last value there.
        newArray[i] = value;

        // Store this array
        PROXY_STORAGE_CONTRACT.setAddressArray(key, newArray);
    }

    /**
     * @notice          Function to delete address array for specific influencer
     */
    function deleteAddressArray(
        bytes32 key
    )
    internal
    {
        address [] memory emptyArray = new address[](0);
        PROXY_STORAGE_CONTRACT.setAddressArray(key, emptyArray);
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

    function deleteReferrerPendingCampaigns(
        bytes32 key
    )
    internal
    {
        deleteAddressArray(key);
    }

    function setReferrerToRebalancedAmountForCycle(
        address referrer,
        uint cycleId,
        uint amount
    )
    internal
    {
        setUint(
            keccak256(_referrer2cycleId2rebalancedAmount, referrer, cycleId),
            amount
        );
    }

    function setReferrersPaidPerDistributionCycle(
        uint cycleId,
        address [] referrers
    )
    internal
    {
        setAddressArray(
            keccak256(_distributionCycleIdToReferrersPaid, cycleId),
            referrers
        );
    }


    function setTotalNonRebalancedPayoutForCycle(
        uint cycleId,
        uint totalNonRebalancedPayout
    )
    internal
    {
        setUint(
            keccak256(_distributionCycle2TotalNonRebalancedPayment, cycleId),
            totalNonRebalancedPayout
        );
    }

    function setTotalRebalancedPayoutForCycle(
        uint cycleId,
        uint totalRebalancedPayout
    )
    internal
    {
        setUint(
            keccak256(_distributionCycleToTotalRebalancedPayment, cycleId),
            totalRebalancedPayout
        );
    }

    function addNewDistributionCycle()
    internal
    returns (uint)
    {
        bytes32 key = keccak256(_numberOfCycles);

        uint incrementedNumberOfCycles = getUint(key) + 1;

        setUint(
            key,
            incrementedNumberOfCycles
        );

        return incrementedNumberOfCycles;
    }

    /**
     * ------------------------------------------------------------------------------------------------
     *              EXTERNAL FUNCTION CALLS - MAINTAINER ACTIONS CAMPAIGN ENDING FUNNEL
     * ------------------------------------------------------------------------------------------------
     */

    /**
     * @notice          Function where maintainer will submit N calls and store campaign
     *                  inside array of campaigns for influencers that it's not distributed but ended
     *
     *                  END CAMPAIGN OPERATION ON PLASMA CHAIN
     * @param           campaignPlasma is the plasma address of campaign
     * @param           start is the start index
     * @param           end is the ending index
     */
    function markCampaignAsDoneAndAssignToActiveInfluencers(
        address campaignPlasma,
        uint start,
        uint end
    )
    public
    onlyMaintainer
    {
        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");

        address[] memory influencers = ITwoKeyPlasmaCampaign(campaignPlasma).getActiveInfluencers(start,end);

        uint i;
        uint len = influencers.length;

        for(i=0; i<len; i++) {
            address referrer = influencers[i];

            ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitAddedPendingRewards(
                campaignPlasma,
                referrer,
                ITwoKeyPlasmaCampaign(campaignPlasma).getReferrerPlasmaBalance(referrer)
            );

            bytes32 key = keccak256(
                _referrer2pendingCampaignAddresses,
                referrer
            );

            pushAddressToArray(key, campaignPlasma);
        }
    }


    /**
     * @notice          At the point when we want to do the payment
     */
    function rebalanceInfluencerRatesAndPrepareForRewardsDistribution(
        address [] referrers,
        uint currentRate2KEY
    )
    public
    onlyMaintainer
    {
        // Counters
        uint i;
        uint j;

        // Increment number of distribution cycles and get the id
        uint cycleId = addNewDistributionCycle();

        // Calculate how much total payout would be for all referrers together in case there was no rebalancing
        uint amountToBeDistributedInCycleNoRebalanced;
        uint amountToBeDistributedInCycleRebalanced;

        for(i=0; i<referrers.length; i++) {
            // Load current referrer
            address referrer = referrers[i];
            // Get all the campaigns of specific referrer
            address[] memory referrerCampaigns = getCampaignsReferrerHasPendingBalances(referrer);
            // Calculate how much is total payout for this referrer
            uint referrerTotalPayoutAmount = 0;
            // Calculate referrer total non-rebalanced amount earned
            uint referrerTotalNonRebalancedAmountForCycle = 0;
            // Iterate through campaigns
            for(j = 0; j < referrerCampaigns.length; j++) {
                // Load campaign address
                address campaignAddress = referrerCampaigns[j];

                uint rebalancedAmount;
                uint nonRebalancedAmount;

                // Update on plasma campaign contract rebalancing ratio at this moment
                (rebalancedAmount, nonRebalancedAmount) = ITwoKeyPlasmaCampaign(campaignAddress).computeAndSetRebalancingRatioForReferrer(
                    referrer,
                    currentRate2KEY
                );

                referrerTotalPayoutAmount = referrerTotalPayoutAmount.add(rebalancedAmount);

                // Store referrer total non-rebalanced amount
                referrerTotalNonRebalancedAmountForCycle = referrerTotalNonRebalancedAmountForCycle.add(nonRebalancedAmount);

                // Update total payout to be paid in case there was no rebalancing
                amountToBeDistributedInCycleNoRebalanced = amountToBeDistributedInCycleNoRebalanced.add(nonRebalancedAmount);
            }

            // Set non rebalanced amount referrer earned in this cycle
            setUint(
                keccak256(_referrer2cycleId2nonRebalancedAmount, referrer, cycleId),
                referrerTotalNonRebalancedAmountForCycle
            );

            // Set inProgress campaigns
            setAddressArray(
                keccak256(_referrer2inProgressCampaignAddress, referrer),
                referrerCampaigns
            );

            // Delete referrer campaigns which are pending rewards
            deleteReferrerPendingCampaigns(
                keccak256(_referrer2pendingCampaignAddresses, referrer)
            );

            // Calculate total amount to be distributed in cycle rebalanced
            amountToBeDistributedInCycleRebalanced = amountToBeDistributedInCycleRebalanced.add(referrerTotalPayoutAmount);

            // Store referrer total payout amount for this cycle
            setReferrerToRebalancedAmountForCycle(
                referrer,
                cycleId,
                referrerTotalPayoutAmount
            );
        }

        // Store total rebalanced payout
        setTotalRebalancedPayoutForCycle(
            cycleId,
            amountToBeDistributedInCycleRebalanced
        );

        // Store total non-rebalanced payout
        setTotalNonRebalancedPayoutForCycle(
            cycleId,
            amountToBeDistributedInCycleNoRebalanced
        );

        // Store all influencers for this distribution cycle.
        setReferrersPaidPerDistributionCycle(cycleId,referrers);
    }


    function finishDistributionCycle(
        uint cycleId,
        uint feePerReferrerIn2KEY
    )
    public
    onlyMaintainer
    {
        address[] memory referrers = getReferrersForCycleId(cycleId);

        uint i;

        address twoKeyPlasmaEventSource = getAddressFromTwoKeySingletonRegistry("TwoKeyPlasmaEventSource");
        // Iterate through all referrers
        for(i=0; i<referrers.length; i++) {
            // Take referrer address
            address referrer = referrers[i];

            address [] memory referrerInProgressCampaigns = getCampaignsInProgressOfDistribution(referrer);
            // Create array of referrer earnings per campaign
            uint [] memory referrerEarningsPerCampaign = new uint [](referrerInProgressCampaigns.length);
            uint j;
            for(j = 0; j < referrerInProgressCampaigns.length; j++) {

                // Load campaign address
                address campaignAddress = referrerInProgressCampaigns[j];

                // Get referrer earnings for this campaign
                referrerEarningsPerCampaign[j] = ITwoKeyPlasmaCampaign(campaignAddress).getReferrerPlasmaBalance(referrer);

                // Mark that referrer got paid his campaign
                ITwoKeyPlasmaCampaign(campaignAddress).markReferrerReceivedPaymentForThisCampaign(referrer);
            }


            ITwoKeyPlasmaEventSource(twoKeyPlasmaEventSource).emitPaidPendingRewards(
                referrer,
                getReferrerEarningsNonRebalancedPerCycle(referrer, cycleId), //amount non rebalanced referrer earned
                getReferrerToTotalRebalancedAmountForCycleId(referrer, cycleId), // amount paid to referrer
                referrerInProgressCampaigns,
                referrerEarningsPerCampaign,
                feePerReferrerIn2KEY
            );

            // Move from inProgress to finished campagins
            appendToArray(
                keccak256(_referrer2finishedAndPaidCampaigns, referrer),
                keccak256(_referrer2inProgressCampaignAddress, referrer)
            );

            // Delete array of inProgress campaigns
            deleteAddressArray(
                keccak256(_referrer2inProgressCampaignAddress, referrer)
            );
        }
    }

    /**
     * ------------------------------------------------
     *        Public getters
     * ------------------------------------------------
     */

    /**
     * @notice          Function to get pending balances for influencers to be distributed
     * @param           referrers is the array of referrers passed previously to function
     *                  rebalanceInfluencerRatesAndPrepareForRewardsDistribution
     */
    function getPendingReferrersPaymentInformationForCycle(
        address [] referrers,
        uint cycleId
    )
    public
    view
    returns (uint[],uint,uint)
    {
        uint numberOfReferrers = referrers.length;
        uint [] memory balances = new uint[](numberOfReferrers);
        uint totalRebalanced;
        uint i;
        for(i = 0; i < numberOfReferrers; i++) {
            balances[i] = getReferrerToTotalRebalancedAmountForCycleId(referrers[i], cycleId);
            totalRebalanced = totalRebalanced.add(balances[i]);
        }

        return (
            balances,
            totalRebalanced,
            getTotalNonRebalancedPayoutForCycle(cycleId)
        );
    }

    /**
     * @notice          Function where we can fetch finished and paid campaigns for referrer
     * @param           referrer is the address of referrer
     */
    function getCampaignsFinishedAndPaidForReferrer(
        address referrer
    )
    public
    view
    returns (address[])
    {
        return getAddressArray(
            keccak256(_referrer2finishedAndPaidCampaigns, referrer)
        );
    }

    /**
     * @notice          Function to get campaign where referrer is having pending
     *                  balance. If empty array, means all rewards are already being
     *                  distributed.
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsReferrerHasPendingBalances(
        address referrer
    )
    public
    view
    returns (address[]) {

        bytes32 key = keccak256(
            _referrer2pendingCampaignAddresses,
            referrer
        );

        return getAddressArray(key);
    }

    /**
     * @notice          Function to fetch total pending payout on all campaigns that
     *                  are not inProgress of payment yet for influencer
     * @param           referrer is the address of referrer
     */
    function getTotalReferrerPendingAmount(
        address referrer
    )
    public
    view
    returns (uint)
    {
        // Get all pending campaigns for this referrer
        address[] memory campaigns = getCampaignsReferrerHasPendingBalances(referrer);

        uint i;
        uint referrerTotalPendingPayout;

        // Iterate through all campaigns
        for(i = 0; i < campaigns.length; i++) {
            // Add to total pending payout referrer plasma balance
            referrerTotalPendingPayout = referrerTotalPendingPayout + ITwoKeyPlasmaCampaign(campaigns[i]).getReferrerPlasmaBalance(referrer);
        }

        // Return referrer total pending
        return referrerTotalPendingPayout;
    }


    /**
     * @notice          Function to get campaign where referrer balance is rebalanced
     *                  but still not submitted to mainchain
     * @param           referrer is the plasma address of referrer
     */
    function getCampaignsInProgressOfDistribution(
        address referrer
    )
    public
    view
    returns (address[])
    {
        bytes32 key = keccak256(
            _referrer2inProgressCampaignAddress,
            referrer
        );

        return getAddressArray(key);
    }


    /**
     * @notice          Function to get how much rebalanced earnings referrer got
     *                  for specific distribution cycle id
     * @param           referrer is the referrer plasma address
     * @param           cycleId is distribution cycle id
     */
    function getReferrerToTotalRebalancedAmountForCycleId(
        address referrer,
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(
                _referrer2cycleId2rebalancedAmount,
                referrer,
                cycleId
            )
        );
    }


    /**
     * @notice          Function to get total payout for specific cycle non rebalanced
     * @param           cycleId is the id of distribution cycle
     */
    function getTotalNonRebalancedPayoutForCycle(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_distributionCycle2TotalNonRebalancedPayment, cycleId)
        );
    }

    /**
     * @notice          Function to get total rebalanced payout for specific cycle rebalanced
     * @param           cycleId is the id of distribution cycle
     */
    function getTotalRebalancedPayoutForCycle(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_distributionCycleToTotalRebalancedPayment, cycleId)
        );
    }

    /**
     * @notice          Function to get exact amount of distribution cycles
     */
    function getNumberOfDistributionCycles()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_numberOfCycles));
    }

    /**
     * @notice          Function to get referrers for cycle id
     * @param           cycleId is the cycle id we want referrers paid in
     */
    function getReferrersForCycleId(
        uint cycleId
    )
    public
    view
    returns (address[])
    {
        return getAddressArray(
            keccak256(_distributionCycleIdToReferrersPaid, cycleId)
        );
    }

    /**
     * @notice          Function to get amount of non rebalanced earnings
     *                  per specific cycle per referrer
     * @param           referrer is the referrer address
     * @param           cycleId is the ID of the cycle.
     */
    function getReferrerEarningsNonRebalancedPerCycle(
        address referrer,
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(
                _referrer2cycleId2nonRebalancedAmount,
                referrer,
                cycleId
            )
        );
    }
}

