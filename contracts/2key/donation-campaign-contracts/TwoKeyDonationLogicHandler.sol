pragma solidity ^0.4.0;

import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyDonationCampaign.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionARC.sol";
import "../interfaces/ITwoKeyEventSource.sol";

//Libraries
import "../libraries/SafeMath.sol";
import "../libraries/Call.sol";
import "../libraries/IncentiveModels.sol";

import "../campaign-mutual-contracts/TwoKeyCampaignIncentiveModels.sol";
import "../upgradable-pattern-campaigns/UpgradeableCampaign.sol";

contract TwoKeyDonationLogicHandler is UpgradeableCampaign, TwoKeyCampaignIncentiveModels {

    using SafeMath for uint256;
    bool initialized;

    IncentiveModel incentiveModel; //Incentive model for rewards
    address public twoKeySingletoneRegistry;
    address public twoKeyDonationCampaign;
    address public ownerPlasma;

    address public twoKeyRegistry;
    address public twoKeyEventSource;
    address public contractor;
    address public moderator;

    uint powerLawFactor;
    uint campaignStartTime; // Time when campaign starts
    uint campaignEndTime; // Time when campaign ends
    uint minDonationAmountWei; // Minimal donation amount
    uint maxDonationAmountWei; // Maximal donation amount
    uint campaignGoal; // Goal of the campaign, how many funds to raise

    string currency;

    mapping(address => uint256) internal referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) internal referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;

    function setInitialParamsDonationLogicHandler(
        uint[] numberValues,
        string currency,
        address _contractor,
        address _moderator,
        address twoKeySingletonRegistry,
        address _twoKeyDonationCampaign
    )
    public
    {
        require(initialized == false);
        twoKeyDonationCampaign = _twoKeyDonationCampaign;
        powerLawFactor = 2;
        campaignStartTime = numberValues[1];
        campaignEndTime = numberValues[2];
        minDonationAmountWei = numberValues[3];
        maxDonationAmountWei = numberValues[4];
        campaignGoal = numberValues[5];
        incentiveModel = IncentiveModel(numberValues[7]);

        contractor = _contractor;
        moderator = _moderator;

        twoKeySingletoneRegistry = twoKeySingletonRegistry;
        twoKeyEventSource = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry)
        .getContractProxyAddress("TwoKeyEventSource");
        twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyRegistry");
        ownerPlasma = plasmaOf(contractor);
        initialized = true;
    }


    /**
     * @notice Function to check for some user how much he can donate
     */
    function howMuchUserCanDonate(uint alreadyDonatedEthWEI) public view returns (uint) {
        if(keccak256(currency) == keccak256('ETH')) {
            uint availableToDonate = maxDonationAmountWei.sub(alreadyDonatedEthWEI);
            return availableToDonate;
        } else {
            address twoKeyExchangeRateContract = ITwoKeySingletoneRegistryFetchAddress(twoKeySingletoneRegistry).getContractProxyAddress("TwoKeyExchangeRateContract");
            uint rate = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getBaseToTargetRate(currency);

            uint totalAmountSpentConvertedToFIAT = (alreadyDonatedEthWEI*rate).div(10**18);
            uint limit = maxDonationAmountWei; // Initially we assume it's fiat currency campaign
            uint leftToSpendInFiats = limit.sub(totalAmountSpentConvertedToFIAT);
            return leftToSpendInFiats;
        }
    }

    function updateReferrerMappings(address referrerPlasma, uint reward, uint conversionId) internal {
        ITwoKeyDonationCampaign(twoKeyDonationCampaign).updateReferrerPlasmaBalance(referrerPlasma,reward);
        referrerPlasma2TotalEarnings2key[referrerPlasma] = referrerPlasma2TotalEarnings2key[referrerPlasma].add(reward);
        referrerPlasma2EarningsPerConversion[referrerPlasma][conversionId] = reward;
        referrerPlasmaAddressToCounterOfConversions[referrerPlasma] += 1;
    }

    /**
     * @notice Update refferal chain with rewards (update state variables)
     * @param _maxReferralRewardETHWei is the max referral reward set
     * @param _converter is the address of the converter
     * @dev This function can only be called by TwoKeyConversionHandler contract
     */
    function updateRefchainRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId,
        uint totalBounty2keys
    )
    public
    {
        require(msg.sender == twoKeyDonationCampaign);

//        Get all the influencers
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

            //Update equal rewards to all influencers but last
            for(i=0; i<numberOfInfluencers - 1; i++) {
                updateReferrerMappings(influencers[i], reward, _conversionId);

            }
            //Update reward for last
            updateReferrerMappings(influencers[numberOfInfluencers-1], rewardForLast, _conversionId);
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
                    uint256 cut = ITwoKeyDonationCampaign(twoKeyDonationCampaign).getReferrerCut(influencers[i]);
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
        }
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
        uint n_influencers = 0;

        while (true) {
            influencer = plasmaOf(ITwoKeyDonationCampaign(twoKeyDonationCampaign).getReceivedFrom(influencer));
            if (influencer == plasmaOf(contractor)) {
                break;
            }
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        influencer = plasmaOf(customer);

        while (n_influencers > 0) {
            influencer = plasmaOf(ITwoKeyDonationCampaign(twoKeyDonationCampaign).getReceivedFrom(influencer));
            n_influencers--;
            influencers[n_influencers] = influencer;
        }
        return influencers;
    }

    /**
     * @notice Function to fetch for the referrer his balance, his total earnings, and how many conversions he participated in
     * @dev only referrer by himself, moderator, or contractor can call this
     * @param _referrer is the address of referrer we're checking for
     * @param signature is the signature if calling functions from FE without ETH address
     * @param conversionIds are the ids of conversions this referrer participated in
     * @return tuple containing this 3 information
     */
    function getReferrerBalanceAndTotalEarningsAndNumberOfConversions(
        address _referrer,
        bytes signature,
        uint[] conversionIds
    )
    public
    view
    returns (uint,uint,uint,uint[])
    {
        if(_referrer != address(0)) {
            require(msg.sender == _referrer || msg.sender == contractor || ITwoKeyReg(twoKeyRegistry).isMaintainer(msg.sender));
            _referrer = plasmaOf(_referrer);
        } else {
            bytes32 hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked("bytes binding referrer to plasma")),
                keccak256(abi.encodePacked("GET_REFERRER_REWARDS"))));
            _referrer = Call.recoverHash(hash, signature, 0);
        }

        uint len = conversionIds.length;
        uint[] memory earnings = new uint[](len);

        for(uint i=0; i<len; i++) {
            earnings[i] = referrerPlasma2EarningsPerConversion[_referrer][conversionIds[i]];
        }

        uint referrerBalance = ITwoKeyDonationCampaign(twoKeyDonationCampaign).getReferrerPlasmaBalance(_referrer);
        return (referrerBalance, referrerPlasma2TotalEarnings2key[_referrer], referrerPlasmaAddressToCounterOfConversions[_referrer], earnings);
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
        ITwoKeyDonationCampaign(twoKeyDonationCampaign).getReceivedFrom(plasma) != address(0)
        || ITwoKeyDonationCampaign(twoKeyDonationCampaign).balanceOf(plasma) > 0) {
            return true;
        }
        return false;
    }



    /**
     * @notice Function to get rewards model present in contract for referrers
     * @return position of the model inside enum IncentiveModel
     */
    function getIncentiveModel() public view returns (IncentiveModel) {
        return incentiveModel;
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
}
