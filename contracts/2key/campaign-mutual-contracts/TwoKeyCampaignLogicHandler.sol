pragma solidity ^0.4.24;

import "./TwoKeyCampaignIncentiveModels.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../interfaces/ITwoKeyEventSourceEvents.sol";
import "../libraries/IncentiveModels.sol";
import "../libraries/Call.sol";

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
