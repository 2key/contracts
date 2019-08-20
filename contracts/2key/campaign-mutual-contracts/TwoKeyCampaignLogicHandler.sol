pragma solidity ^0.4.24;

import "./TwoKeyCampaignIncentiveModels.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyMaintainersRegistry.sol";
import "../interfaces/ITwoKeySingletoneRegistryFetchAddress.sol";
import "../interfaces/ITwoKeyExchangeRateContract.sol";

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




}
