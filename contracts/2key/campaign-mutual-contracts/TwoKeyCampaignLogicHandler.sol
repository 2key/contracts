pragma solidity ^0.4.24;

import "./TwoKeyCampaignIncentiveModels.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/ITwoKeyCampaign.sol";
import "../libraries/Call.sol";

contract TwoKeyCampaignLogicHandler is TwoKeyCampaignIncentiveModels {

    using SafeMath for uint256;

    /**
     * Will be set once initial parameters are set and
     * will never be changed after that
     */
    bool initialized;

    IncentiveModel incentiveModel; //Incentive model for rewardsaddress twoKeyMaintainersRegistry;

    address twoKeyMaintainersRegistry;
    address twoKeyRegistry;
    address twoKeySingletonRegistry;
    address twoKeyEventSource;

    address public twoKeyCampaign;
    address public conversionHandler;

    address ownerPlasma;
    address contractor;
    address moderator;

    uint minContributionAmountWei; //Minimal contribution
    uint maxContributionAmountWei; //Maximal contribution
    uint campaignStartTime; // Time when campaign start
    uint campaignEndTime; // Time when campaign ends

    string public currency; // Currency campaign is currently in

    uint public campaignRaisedAlready;

    mapping(address => uint256) public referrerPlasma2TotalEarnings2key; // Total earnings for referrers
    mapping(address => uint256) public referrerPlasmaAddressToCounterOfConversions; // [referrer][conversionId]
    mapping(address => mapping(uint256 => uint256)) internal referrerPlasma2EarningsPerConversion;

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
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));

        uint numberOfAddresses = _referrerPlasmaList.length;
        uint256[] memory referrersPendingPlasmaBalance = new uint256[](numberOfAddresses);
        uint256[] memory referrersTotalEarningsPlasmaBalance = new uint256[](numberOfAddresses);

        for (uint i=0; i<numberOfAddresses; i++){
            referrersPendingPlasmaBalance[i] = ITwoKeyCampaign(twoKeyCampaign).getReferrerPlasmaBalance(_referrerPlasmaList[i]);
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
            require(msg.sender == _referrerAddress || msg.sender == contractor || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).onlyMaintainer(msg.sender));
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

        address _address;

        if(msg.sender == contractor || msg.sender == eth_address) {
            flag = true;
        } else {
            _address = recover(signature);
            if(_address == ownerPlasma) {
                flag = true;
            }
        }
        bytes memory stats = getAddressStatistic(_user, plasma, flag, _address);
        return abi.encodePacked(userData, isJoined, eth_address, stats);
    }

    function getAddressStatistic(
        address _address,
        bool plasma,
        bool flag,
        address referrer
    )
    internal
    view
    returns (bytes);

}
