pragma solidity ^0.4.13;

contract TwoKeyCampaignIncentiveModels {
    enum IncentiveModel {MANUAL, VANILLA_AVERAGE, VANILLA_AVERAGE_LAST_3X, VANILLA_POWER_LAW, NO_REFERRAL_REWARD}
}

contract TwoKeyCampaignLogicHandler is TwoKeyCampaignIncentiveModels {

    using SafeMath for uint256;

    /**
     * Will be set once initial parameters are set and
     * will never be changed after that
     */
    bool initialized;

    IncentiveModel incentiveModel; //Incentive model for rewards;

    address twoKeyRegistry;
    address twoKeySingletonRegistry;

    address public twoKeyCampaign;
    address public conversionHandler;

    address ownerPlasma;
    address contractor;
    address moderator;

    uint minContributionAmountWei; //Minimal contribution
    uint maxContributionAmountWei; //Maximal contribution
    uint campaignStartTime; // Time when campaign start
    uint campaignEndTime; // Time when campaign ends

    uint public constant ALLOWED_GAP = 1000000000000000000; //1% allowed GAP for ETH conversions in case FIAT is campaign currency
    string public currency; // Currency campaign is currently in

    uint public campaignRaisedIncludingPendingConversions;
    bool endCampaignOnceGoalReached;

    mapping(address => uint256) public referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) public referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;
    mapping(address => uint) converterToLastDebtPaid;


    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    function getAddressFromRegistry(string contractName) internal view returns (address) {
        return ITwoKeySingletoneRegistryFetchAddress(twoKeySingletonRegistry).getContractProxyAddress(contractName);
    }

    function getRateFromExchange() internal view returns (uint) {
        address ethUSDExchangeContract = getAddressFromRegistry("TwoKeyExchangeRateContract");
        uint rate = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getBaseToTargetRate(currency);
        return rate;
    }

    /**
     * @notice Function to determine plasma address of ethereum address
     * @param me is the address (ethereum) of the user
     * @return an address
     */
    function plasmaOf(
        address me
    )
    public
    view
    returns (address)
    {
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(
        address me
    )
    public
    view
    returns (address)
    {
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    /**
     * @notice Function to get rewards model present in contract for referrers
     * @return position of the model inside enum IncentiveModel
     */
    function getIncentiveModel() public view returns (IncentiveModel) {
        return incentiveModel;
    }

    /**
     * @notice Requirement for the checking if the campaign is active or not
     */
    function checkIsCampaignActiveInTermsOfTime()
    internal
    view
    returns (bool)
    {
        if(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime) {
            return true;
        }
        return false;
    }

    /**
     * @notice Function to check if the msg.sender has already joined
     * @return true/false depending of joined status
     */
    function getAddressJoinedStatus(
        address _address
    )
    public
    view
    returns (bool)
    {
        address plasma = plasmaOf(_address);
        if (_address == address(0)) {
            return false;
        }
        if (plasma == ownerPlasma || _address == address(moderator) ||
        ITwoKeyCampaign(twoKeyCampaign).getReceivedFrom(plasma) != address(0)
        || ITwoKeyCampaign(twoKeyCampaign).balanceOf(plasma) > 0) {
            return true;
        }
        return false;
    }

    /**
     * @notice Internal helper function
     */
    function recover(
        bytes signature
    )
    internal
    view
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
            keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
        address x = Call.recoverHash(hash, signature, 0);
        return x;
    }

    /**
     * @notice Function to get balance and total earnings for all referrer addresses passed in arg
     * @param _referrerPlasmaList is the array of plasma addresses of referrer
     * @return two arrays. 1st contains current plasma balance and 2nd contains total plasma balances
     */
    function getReferrersBalancesAndTotalEarnings(
        address[] _referrerPlasmaList
    )
    public
    view
    returns (uint256[], uint256[])
    {
        require(
            ITwoKeyMaintainersRegistry(getAddressFromRegistry("TwoKeyMaintainersRegistry"))
                .checkIsAddressMaintainer(msg.sender)
        );

        uint numberOfAddresses = _referrerPlasmaList.length;
        uint256[] memory referrersPendingPlasmaBalance = new uint256[](numberOfAddresses);
        uint256[] memory referrersTotalEarningsPlasmaBalance = new uint256[](numberOfAddresses);

        for (uint i=0; i<numberOfAddresses; i++){
            referrersPendingPlasmaBalance[i] = ITwoKeyCampaign(twoKeyCampaign)
                .getReferrerPlasmaBalance(_referrerPlasmaList[i]);

            referrersTotalEarningsPlasmaBalance[i] = referrerPlasma2TotalEarnings2key[_referrerPlasmaList[i]];
        }

        return (referrersPendingPlasmaBalance, referrersTotalEarningsPlasmaBalance);
    }

    /**
     * @notice Function to fetch for the referrer his balance, his total earnings, and how many conversions he participated in
     * @dev only referrer by himself, moderator, or contractor can call this
     * @param _referrerAddress is the address of referrer we're checking for
     * @param _sig is the signature if calling functions from FE without ETH address
     * @param _conversionIds ar e the ids of conversions this referrer participated in
     * @return tuple containing this 3 information
     */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(
        address _referrerAddress,
        bytes _sig,
        uint[] _conversionIds
    )
    public
    view
    returns (uint,uint,uint,uint[],address)
    {
        if(_sig.length > 0) {
            _referrerAddress = recover(_sig);
        }
        else {
            _referrerAddress = plasmaOf(_referrerAddress);
        }

        uint len = _conversionIds.length;
        uint[] memory earnings = new uint[](len);

        for(uint i=0; i<len; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrerAddress][_conversionIds[i]];
        }

        uint referrerBalance = ITwoKeyCampaign(twoKeyCampaign).getReferrerPlasmaBalance(_referrerAddress);
        return (referrerBalance, referrerPlasma2TotalEarnings2key[_referrerAddress], referrerPlasmaAddressToCounterOfConversions[_referrerAddress], earnings, _referrerAddress);
    }

    /**
     * @notice Function to get super statistics
     * @param _user is the user address we want stats for
     * @param plasma is if that address is plasma or not
     * @param signature in case we're calling this from referrer who doesn't have yet opened wallet
     */
    function getSuperStatistics(
        address _user,
        bool plasma,
        bytes signature
    )
    public
    view
    returns (bytes)
    {
        address eth_address = _user;

        if (plasma) {
            (eth_address) = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_user);
        }

        bytes memory userData = ITwoKeyReg(twoKeyRegistry).getUserData(eth_address);

        bool isJoined = getAddressJoinedStatus(_user);
        bool flag;

        bytes memory stats = getAddressStatistic(_user, plasma);
        return abi.encodePacked(userData, isJoined, eth_address, stats);
    }

    /**
     * @notice Function to return referrers participated in the referral chain
     * @param customer is the one who converted (bought tokens)
     * @return array of referrer addresses
     */
    function getReferrers(
        address customer
    )
    public
    view
    returns (address[])
    {

        address influencer = plasmaOf(customer);

        uint numberOfInfluencers = ITwoKeyCampaign(twoKeyCampaign).getNumberOfUsersToContractor(customer);

        address[] memory influencers = new address[](numberOfInfluencers);

        while(numberOfInfluencers > 0) {
            influencer = ITwoKeyCampaign(twoKeyCampaign).getReceivedFrom(influencer);
            numberOfInfluencers--;
            influencers[numberOfInfluencers] = influencer;
        }
        return influencers;
    }

    function getAddressStatistic(
        address _address,
        bool plasma
    )
    internal
    view
    returns (bytes);

    /**
     * @notice Function to update MinContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new value we are going to set for minContributionETH
     */
    function updateMinContributionETHOrUSD(
        uint value
    )
    public
    onlyContractor
    {
        minContributionAmountWei = value;
    }

    /**
     * @notice Function to update maxContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new maxContribution value
     */
    function updateMaxContributionETHorUSD(
        uint value
    )
    public
    onlyContractor
    {
        maxContributionAmountWei = value;
    }

    /**
     * @notice Gets total earnings for referrer plasma address
     * @param _referrer is the address of influencer
     */
    function getReferrerPlasmaTotalEarnings(
        address _referrer
    )
    public
    view
    returns (uint)
    {
        return referrerPlasma2TotalEarnings2key[_referrer];
    }

    /**
     * @notice Function which will update total raised funds which will be always compared with hard cap
     * @param newAmount is the value including the new conversion amount
     */
    function updateTotalRaisedFunds(uint newAmount) internal {
        campaignRaisedIncludingPendingConversions = newAmount;
    }

    /**
     * @notice Function to reduce total raised funds after the conversion is rejected
     * @param amountToReduce is the amount of money we'll reduce from conversion total raised
     */
    function reduceTotalRaisedFundsAfterConversionRejected(uint amountToReduce) public {
        require(msg.sender == conversionHandler);
        campaignRaisedIncludingPendingConversions = campaignRaisedIncludingPendingConversions.sub(amountToReduce);
    }


    function updateReferrerMappings(
        address referrerPlasma,
        uint reward,
        uint conversionId
    )
    internal
    {
        ITwoKeyCampaign(twoKeyCampaign).updateReferrerPlasmaBalance(referrerPlasma,reward);
        referrerPlasma2TotalEarnings2key[referrerPlasma] = referrerPlasma2TotalEarnings2key[referrerPlasma].add(reward);
        referrerPlasma2EarningsPerConversion[referrerPlasma][conversionId] = reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] = referrerPlasmaAddressToCounterOfConversions[referrerPlasma].add(1);
        ITwoKeyEventSourceEvents(getAddressFromRegistry("TwoKeyEventSource")).rewarded(twoKeyCampaign, referrerPlasma, reward);
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(
        address _converter,
        uint _conversionId,
        uint totalBounty2keys
    )
    public
    {
        require(msg.sender == twoKeyCampaign);

        //Get all the influencers
        address[] memory influencers = getReferrers(_converter);

        //Get array length
        uint numberOfInfluencers = influencers.length;

        uint i;
        uint reward;
        if(incentiveModel == IncentiveModel.VANILLA_AVERAGE) {
            reward = IncentiveModels.averageModelRewards(totalBounty2keys, numberOfInfluencers);
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], reward, _conversionId);
            }
        } else if (incentiveModel == IncentiveModel.VANILLA_AVERAGE_LAST_3X) {
            uint rewardForLast;
            // Calculate reward for regular ones and for the last
            (reward, rewardForLast) = IncentiveModels.averageLast3xRewards(totalBounty2keys, numberOfInfluencers);
            if(numberOfInfluencers > 0) {
                //Update equal rewards to all influencers but last
                for(i=0; i<numberOfInfluencers - 1; i++) {
                    updateReferrerMappings(influencers[i], reward, _conversionId);
                }
                //Update reward for last
                updateReferrerMappings(influencers[numberOfInfluencers-1], rewardForLast, _conversionId);
            }
        } else if(incentiveModel == IncentiveModel.VANILLA_POWER_LAW) {
            // Get rewards per referrer
            uint [] memory rewards = IncentiveModels.powerLawRewards(totalBounty2keys, numberOfInfluencers, 2);
            //Iterate through all referrers and distribute rewards
            for(i=0; i<numberOfInfluencers; i++) {
                updateReferrerMappings(influencers[i], rewards[i], _conversionId);
            }
        } else if(incentiveModel == IncentiveModel.MANUAL) {
            for (i = 0; i < numberOfInfluencers; i++) {
                uint256 b;

                if (i == influencers.length - 1) {  // if its the last influencer then all the bounty goes to it.
                    b = totalBounty2keys;
                }
                else {
                    uint256 cut = ITwoKeyCampaign(twoKeyCampaign).getReferrerCut(influencers[i]);
                    if (cut > 0 && cut <= 101) {
                        b = totalBounty2keys.mul(cut.sub(1)).div(100);
                    } else {// cut == 0 or 255 indicates equal particine of the bounty
                        b = totalBounty2keys.div(influencers.length - i);
                    }
                }

                updateReferrerMappings(influencers[i], b, _conversionId);
                //Decrease bounty for distributed
                totalBounty2keys = totalBounty2keys.sub(b);
            }
        } else if(incentiveModel == IncentiveModel.NO_REFERRAL_REWARD) {
            for(i=0; i<numberOfInfluencers; i++) {
                referrerPlasmaAddressToCounterOfConversions[influencers[i]] = referrerPlasmaAddressToCounterOfConversions[influencers[i]].add(1);
            }
        }
    }

//    function updateConverterToLastDebtPaid(
//        address _converter,
//        uint _amountPaid
//    )
//    public
//    {
//        require(msg.sender == twoKeyCampaign);
//        converterToLastDebtPaid[_converter] = _amountPaid;
//    }

}

contract ITwoKeyCampaign {

    function getNumberOfUsersToContractor(
        address _user
    )
    public
    view
    returns (uint);

    function getReceivedFrom(
        address _receiver
    )
    public
    view
    returns (address);

    function balanceOf(
        address _owner
    )
    public
    view
    returns (uint256);

    function getReferrerCut(
        address me
    )
    public
    view
    returns (uint256);

    function getReferrerPlasmaBalance(
        address _influencer
    )
    public
    view
    returns (uint);

    function updateReferrerPlasmaBalance(
        address _influencer,
        uint _balance
    )
    public;

    function updateModeratorRewards(
        uint moderatorTokens
    )
    public;

    address public logicHandler;
    address public conversionHandler;

}

contract ITwoKeyDonationCampaign {
    address public logicHandler;
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public;

    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint);

    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelledOrRejected(address _cancelledConverter, uint _conversionAmount) public;
}

contract ITwoKeyDonationConversionHandler {
    function supportForCreateConversion(
        address _converterAddress,
        uint _conversionAmount,
        uint _maxReferralRewardETHWei,
        bool _isKYCRequired,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;

    function getAmountConverterSpent(
        address converter
    )
    public
    view
    returns (uint);

    function getAmountOfDonationTokensConverterReceived(
        address converter
    )
    public
    view
    returns (uint);

    function getStateForConverter(
        address _converter
    )
    external
    view
    returns (bytes32);

    function setExpiryConversionInHours(
        uint _expiryConversionInHours
    )
    public;

}

contract ITwoKeyEventSourceEvents {
    // This 2 functions will be always in the interface since we need them very often
    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);

    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external;

    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external;

    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external;

    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external;

    function priceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    )
    external;

    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external;

    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external;


    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public;


}

contract ITwoKeyExchangeRateContract {
    function getBaseToTargetRate(string _currency) public view returns (uint);
    function getStableCoinTo2KEYQuota(address stableCoinAddress) public view returns (uint,uint);
    function getStableCoinToUSDQuota(address stableCoin) public view returns (uint);
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyReg {
    function addTwoKeyEventSource(address _twoKeyEventSource) public;
    function changeTwoKeyEventSource(address _twoKeyEventSource) public;
    function addWhereContractor(address _userAddress, address _contractAddress) public;
    function addWhereModerator(address _userAddress, address _contractAddress) public;
    function addWhereReferrer(address _userAddress, address _contractAddress) public;
    function addWhereConverter(address _userAddress, address _contractAddress) public;
    function getContractsWhereUserIsContractor(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsModerator(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsRefferer(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsConverter(address _userAddress) public view returns (address[]);
    function getTwoKeyEventSourceAddress() public view returns (address);
    function addName(string _name, address _sender, string _fullName, string _email, bytes signature) public;
    function addNameByUser(string _name) public;
    function getName2Owner(string _name) public view returns (address);
    function getOwner2Name(address _sender) public view returns (string);
    function getPlasmaToEthereum(address plasma) public view returns (address);
    function getEthereumToPlasma(address ethereum) public view returns (address);
    function checkIfTwoKeyMaintainerExists(address _maintainer) public view returns (bool);
    function getUserData(address _user) external view returns (bytes);
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

library Call {
    function params0(address c, bytes _method) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x04, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params1(address c, bytes _method, uint _val) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
        // move pointer to free memory spot
            let ptr := mload(0x40)
        // put function sig at memory spot
            mstore(ptr,sig)
        // append argument after function sig
            mstore(add(ptr,0x04), _val)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x24, // Inputs are 0 bytes long
            ptr,  //Store output over input
            0x20) //Outputs are 1 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
    }

    function params2(address c, bytes _method, uint _val1, uint _val2) public view returns (uint answer) {
        // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
        //    dc = c;
        bytes4 sig = bytes4(keccak256(_method));
        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), _val1)
            mstore(add(ptr,0x24), _val2)

            let result := call(  // use WARNING because this should be staticcall BUT geth crash!
            15000, // gas limit
            c, // sload(dc_slot),  // to addr. append var to _slot to access storage variable
            0, // not transfer any ether (comment if using staticcall)
            ptr, // Inputs are stored at location ptr
            0x44, // Inputs are 4 bytes for signature and 2 uint256
            ptr,  //Store output over input
            0x20) //Outputs are 1 uint long

            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x20)) // Set storage pointer to new space
        }
    }

    function loadAddress(bytes sig, uint idx) public pure returns (address) {
        address influencer;
        idx += 20;
        assembly
        {
            influencer := mload(add(sig, idx))
        }
        return influencer;
    }

    function loadUint8(bytes sig, uint idx) public pure returns (uint8) {
        uint8 weight;
        idx += 1;
        assembly
        {
            weight := mload(add(sig, idx))
        }
        return weight;
    }


    function recoverHash(bytes32 hash, bytes sig, uint idx) public pure returns (address) {
        // same as recoverHash in utils/sign.js
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        require (sig.length >= 65+idx, 'bad signature length');
        idx += 32;
        bytes32 r;
        assembly
        {
            r := mload(add(sig, idx))
        }

        idx += 32;
        bytes32 s;
        assembly
        {
            s := mload(add(sig, idx))
        }

        idx += 1;
        uint8 v;
        assembly
        {
            v := mload(add(sig, idx))
        }
        if (v >= 32) { // handle case when signature was made with ethereum web3.eth.sign or getSign which is for signing ethereum transactions
            v -= 32;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32"; // 32 is the number of bytes in the following hash
            hash = keccak256(abi.encodePacked(prefix, hash));
        }
        if (v <= 1) v += 27;
        require(v==27 || v==28,'bad sig v');
        //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol#L57
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'bad sig s');
        return ecrecover(hash, v, r, s);

    }

    function recoverSigMemory(bytes sig) private pure returns (address[], address[], uint8[], uint[], uint) {
        uint8 version = loadUint8(sig, 0);
        uint msg_len = (version == 1) ? 1+65+20 : 1+20+20;
        uint n_influencers = (sig.length-21) / (65+msg_len);
        uint8[] memory weights = new uint8[](n_influencers);
        address[] memory keys = new address[](n_influencers);
        if ((sig.length-21) % (65+msg_len) > 0) {
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        uint[] memory offsets = new uint[](n_influencers);

        return (influencers, keys, weights, offsets, msg_len);
    }

    function recoverSigParts(bytes sig, address last_address) private pure returns (address[], address[], uint8[], uint[]) {
        // sig structure:
        // 1 byte version 0 or 1
        // 20 bytes are the address of the contractor or the influencer who created sig.
        //  this is the "anchor" of the link
        //  It must have a public key aleady stored for it in public_link_key
        // Begining of a loop on steps in the link:
        // * 65 bytes are step-signature using the secret from previous step
        // * message of the step that is going to be hashed and used to compute the above step-signature.
        //   message length depend on version 41 (version 0) or 86 (version 1):
        //   * 1 byte cut (percentage) each influencer takes from the bounty. the cut is stored in influencer2cut or weight for voting
        //   * 20 bytes address of influencer (version 0) or 65 bytes of signature of cut using the influencer address to sign
        //   * 20 bytes public key of the last secret
        // In the last step the message can be optional. If it is missing the message used is the address of the sender
        uint idx = 0;
        uint msg_len;
        uint8[] memory weights;
        address[] memory keys;
        address[] memory influencers;
        uint[] memory offsets;
        (influencers, keys, weights, offsets, msg_len) = recoverSigMemory(sig);
        idx += 1;  // skip version

        idx += 20; // skip old_address which should be read by the caller in order to get old_key
        uint count_influencers = 0;

        while (idx + 65 <= sig.length) {
            offsets[count_influencers] = idx;
            idx += 65;  // idx was increased by 65 for the signature at the begining which we will process later

            if (idx + msg_len <= sig.length) {  // its  a < and not a <= because we dont want this to be the final iteration for the converter
                weights[count_influencers] = loadUint8(sig, idx);
                require(weights[count_influencers] > 0,'weight not defined (1..255)');  // 255 are used to indicate default (equal part) behaviour
                idx++;


                if (msg_len == 41)  // 1+20+20 version 0
                {
                    influencers[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                    keys[count_influencers] = loadAddress(sig, idx);
                    idx += 20;
                } else if (msg_len == 86)  // 1+65+20 version 1
                {
                    keys[count_influencers] = loadAddress(sig, idx+65);
                    influencers[count_influencers] = recoverHash(
                        keccak256(
                            abi.encodePacked(
                                keccak256(abi.encodePacked("bytes binding to weight","bytes binding to public")),
                                keccak256(abi.encodePacked(weights[count_influencers],keys[count_influencers]))
                            )
                        ),sig,idx);
                    idx += 65;
                    idx += 20;
                }

            } else {
                // handle short signatures generated with free_take
                influencers[count_influencers] = last_address;
            }
            count_influencers++;
        }
        require(idx == sig.length,'illegal message size');

        return (influencers, keys, weights, offsets);
    }

    function recoverSig(bytes sig, address old_key, address last_address) public pure returns (address[], address[], uint8[]) {
        // validate sig AND
        // recover the information from the signature: influencers, public_link_keys, weights/cuts
        // influencers may have one more address than the keys and weights arrays
        //
        require(old_key != address(0),'no public link key');

        address[] memory influencers;
        address[] memory keys;
        uint8[] memory weights;
        uint[] memory offsets;
        (influencers, keys, weights, offsets) = recoverSigParts(sig, last_address);

        // check if we received a valid signature
        for(uint i = 0; i < influencers.length; i++) {
            if (i < weights.length) {
                require (recoverHash(keccak256(abi.encodePacked(weights[i], keys[i], influencers[i])),sig,offsets[i]) == old_key, 'illegal signature');
                old_key = keys[i];
            } else {
                // signed message for the last step is the address of the converter
                require (recoverHash(keccak256(abi.encodePacked(influencers[i])),sig,offsets[i]) == old_key, 'illegal last signature');
            }
        }

        return (influencers, keys, weights);
    }
}

library IncentiveModels {
    using SafeMath for uint;
    /**
     * @notice Implementation of average incentive model, reward is splited equally per referrer
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     */
    function averageModelRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint) {
        if(numberOfInfluencers > 0) {
            uint equalPart = totalBounty.div(numberOfInfluencers);
            return equalPart;
        }
        return 0;
    }

    /**
     * @notice Implementation similar to average incentive model, except direct referrer) - gets 3x as the others
     * @param totalBounty is total reward for the influencers
     * @param numberOfInfluencers is how many influencers we're splitting reward between
     * @return two values, first is reward per regular referrer, and second is reward for last referrer in the chain
     */
    function averageLast3xRewards(
        uint totalBounty,
        uint numberOfInfluencers
    ) internal pure returns (uint,uint) {
        if(numberOfInfluencers> 0) {
            uint rewardPerReferrer = totalBounty.div(numberOfInfluencers.add(2));
            uint rewardForLast = rewardPerReferrer.mul(3);
            return (rewardPerReferrer, rewardForLast);
        }
        return (0,0);
    }

    /**
     * @notice Function to return array of corresponding values with rewards in power law schema
     * @param totalBounty is totalReward
     * @param numberOfInfluencers is the total number of influencers
     * @return rewards in wei
     */
    function powerLawRewards(
        uint totalBounty,
        uint numberOfInfluencers,
        uint factor
    ) internal pure returns (uint[]) {
        uint[] memory rewards = new uint[](numberOfInfluencers);
        if(numberOfInfluencers > 0) {
            uint x = calculateX(totalBounty,numberOfInfluencers,factor);
            for(uint i=0; i<numberOfInfluencers;i++) {
                rewards[numberOfInfluencers.sub(i.add(1))] = x.div(factor**i);
            }
        }
        return rewards;
    }


    /**
     * @notice Function to calculate base for all rewards in power law model
     * @param sumWei is the total reward to be splited in Wei
     * @param numberOfElements is the number of referrers in the chain
     * @return wei value of base for the rewards in power law
     */
    function calculateX(
        uint sumWei,
        uint numberOfElements,
        uint factor
    ) private pure returns (uint) {
        uint a = 1;
        uint sumOfFactors = 1;
        for(uint i=1; i<numberOfElements; i++) {
            a = a.mul(factor);
            sumOfFactors = sumOfFactors.add(a);
        }
        return sumWei.mul(a).div(sumOfFactors);
    }
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

contract UpgradeabilityCampaignStorage {

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

contract UpgradeableCampaign is UpgradeabilityCampaignStorage {

}

contract TwoKeyDonationLogicHandler is UpgradeableCampaign, TwoKeyCampaignLogicHandler {

    uint public powerLawFactor; // Factor

    uint campaignGoal; // Goal of the campaign, how many funds to raise


    function setInitialParamsDonationLogicHandler(
        uint[] numberValues,
        string _currency,
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
        address _twoKeyDonationCampaign,
        address _twoKeyDonationConversionHandler
    )
    public
    {
        require(initialized == false);

        twoKeyCampaign = _twoKeyDonationCampaign;
        conversionHandler = _twoKeyDonationConversionHandler;

        powerLawFactor = 2;
        campaignStartTime = numberValues[1];
        campaignEndTime = numberValues[2];
        minContributionAmountWei = numberValues[3];
        maxContributionAmountWei = numberValues[4];
        campaignGoal = numberValues[5];
        incentiveModel = IncentiveModel(numberValues[7]);

        if(keccak256(_currency) == keccak256('ETH')) {
            require(numberValues[3] >= (10**16));
        } else {
            require(numberValues[3] >= (10**18));
        }

        if(numberValues[8] == 1) {
            endCampaignOnceGoalReached = true;
        }

        contractor = _contractor;
        moderator = _moderator;
        currency = _currency;

        if(keccak256(_currency) == keccak256('ETH')) {
            require(numberValues[3] >= (10**16));
        } else {
            require(numberValues[3] >= (10**18));
        }

        twoKeySingletonRegistry = _twoKeySingletonRegistry;
        twoKeyRegistry = getAddressFromRegistry("TwoKeyRegistry");

        ownerPlasma = plasmaOf(contractor);
        initialized = true;
    }

    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, uint debtPaid) public returns (bool,uint) {
        require(msg.sender == twoKeyCampaign);
        require(canConversionBeCreatedInTermsOfMinMaxContribution(converter, conversionAmount.add(debtPaid)) == true);
        uint conversionAmountInCampaignCurrency = convertConversionAmountToCampaignCurrency(conversionAmount);
        require(updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(conversionAmountInCampaignCurrency) == true);
        require(checkIsCampaignActiveInTermsOfTime() == true);
        return (true, conversionAmountInCampaignCurrency);
    }

    function canConversionBeCreatedInTermsOfMinMaxContribution(address converter, uint conversionAmountEthWEI) public view returns (bool) {
        uint leftToSpendInCampaignCurrency = checkHowMuchUserCanSpend(converter);
        if(keccak256(currency) == keccak256("ETH")) {
            if(leftToSpendInCampaignCurrency.add(1000) >= conversionAmountEthWEI && conversionAmountEthWEI.add(1000) >= minContributionAmountWei) {
                return true;
            }
        } else {
            uint rate = getRateFromExchange();
            uint conversionAmountCampaignCurrency = (conversionAmountEthWEI.mul(rate)).div(10**18);
            if(leftToSpendInCampaignCurrency.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18)) >= conversionAmountCampaignCurrency &&
                minContributionAmountWei <= conversionAmountCampaignCurrency.mul(100 * (10**18) + ALLOWED_GAP).div(100 * (10**18))
            ) {
                return true;
            }
        }
        return false;
    }

    // Updated
    function checkHowMuchUserCanSpend(
        address _converter
    )
    public
    view
    returns (uint)
    {
        uint amountAlreadySpentEth = ITwoKeyDonationConversionHandler(conversionHandler).getAmountConverterSpent(_converter);
        uint leftToSpend = getHowMuchLeftForUserToSpend(amountAlreadySpentEth);
        return leftToSpend;
    }



    function checkHowMuchUserCanContributeIncludingGoalAndMaxConversionAmount(
        address _converter
    )
    public
    view
    returns (uint)
    {
        //Get how much user can spend in terms of min/max contribution
        uint leftToSpendInCampaignCurrency = checkHowMuchUserCanSpend(_converter);
        if(endCampaignOnceGoalReached == true) {
            if(campaignRaisedIncludingPendingConversions.add(leftToSpendInCampaignCurrency) > campaignGoal) {
                return campaignGoal.sub(campaignRaisedIncludingPendingConversions);
            }
        }
        return leftToSpendInCampaignCurrency;
    }

    /**
     * @notice Function to check for some user how much he can donate
     */
    function getHowMuchLeftForUserToSpend(
        uint alreadyDonatedEthWEI
    )
    internal
    view
    returns (uint)
    {
        if(keccak256(currency) == keccak256('ETH')) {
            uint availableToDonate = maxContributionAmountWei.sub(alreadyDonatedEthWEI);
            return availableToDonate;
        } else {
            uint rate = getRateFromExchange();

            uint totalAmountSpentConvertedToFIAT = (alreadyDonatedEthWEI*rate).div(10**18);
            uint limit = maxContributionAmountWei; // Initially we assume it's fiat currency campaign
            uint leftToSpendInFiats = limit.sub(totalAmountSpentConvertedToFIAT);
            return leftToSpendInFiats;
        }
    }


    /**
     * @notice Function to fetch stats for the address
     */
    function getAddressStatistic(
        address _address,
        bool plasma
    )
    internal
    view
    returns (bytes)
    {
        bytes32 state; // NOT-EXISTING AS CONVERTER DEFAULT STATE

        address eth_address = ethereumOf(_address);
        address plasma_address = plasmaOf(_address);

        if(_address == contractor) {
            return abi.encodePacked(0, 0, 0, false, false);
        } else {
            bool isConverter;
            bool isReferrer;

            uint amountConverterSpent = ITwoKeyDonationConversionHandler(conversionHandler).getAmountConverterSpent(eth_address);
            uint amountOfTokensReceived = ITwoKeyDonationConversionHandler(conversionHandler).getAmountOfDonationTokensConverterReceived(eth_address);

            if(amountConverterSpent> 0) {
                isConverter = true;
                state = ITwoKeyDonationConversionHandler(conversionHandler).getStateForConverter(eth_address);
            }

            if(referrerPlasma2TotalEarnings2key[plasma_address] > 0) {
                isReferrer = true;
            }

            return abi.encodePacked(
                amountConverterSpent,
                referrerPlasma2TotalEarnings2key[plasma_address],
                amountOfTokensReceived,
                isConverter,
                isReferrer,
                state
            );
        }
    }


    function convertConversionAmountToCampaignCurrency(uint conversionAmount) internal view returns (uint) {
        if(keccak256(currency) != keccak256('ETH')) {
            uint rate = getRateFromExchange();
            return conversionAmount.mul(rate).div(10**18);
        }
        return conversionAmount;
    }

    /**
     * @notice Function to update total raised funds and validate conversion in terms of campaign goal
     */
    function updateRaisedFundsAndValidateConversionInTermsOfCampaignGoal(uint conversionAmountInCampaignCurrency) internal returns (bool) {
        uint newTotalRaisedFunds = campaignRaisedIncludingPendingConversions.add(conversionAmountInCampaignCurrency);
        require(canConversionBeCreatedInTermsOfCampaignGoal(newTotalRaisedFunds)); // checking that criteria is satisfied
        updateTotalRaisedFunds(newTotalRaisedFunds); //updating new total raised funds
        return true;
    }

    /**
     * @notice Function which will validate if conversion can be created if endCampaignOnceGoalReached is selected
     * @param campaignRaisedIncludingConversion is how much will be total campaign raised with new conversion
     */
    function canConversionBeCreatedInTermsOfCampaignGoal(uint campaignRaisedIncludingConversion) internal view returns (bool) {
        if(endCampaignOnceGoalReached == true) {
            require(campaignRaisedIncludingConversion <= campaignGoal.add(minContributionAmountWei)); //small GAP
        }
        return true;
    }


    /**
     * @notice Function to check if campaign has ended
     */
    function isCampaignEnded() internal view returns (bool) {
        if(checkIsCampaignActiveInTermsOfTime() == false) {
            return true;
        }
        if(endCampaignOnceGoalReached == true && campaignRaisedIncludingPendingConversions.add(minContributionAmountWei) >= campaignGoal) {
            return true;
        }
        return false;
    }

    function getConstantInfo()
    public
    view
    returns (uint,uint,uint,uint,uint)
    {
        return (
            campaignStartTime,
            campaignEndTime,
            minContributionAmountWei,
            maxContributionAmountWei,
            campaignGoal
        );
    }
}

