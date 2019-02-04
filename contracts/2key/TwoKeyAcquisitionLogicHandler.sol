pragma solidity ^0.4.24;
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/IERC20.sol";
import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/IAcquisitionGetReceivedFrom.sol";
/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract TwoKeyAcquisitionLogicHandler {

    using SafeMath for uint256;

    address public twoKeyRegistry;
    address contractor;
    address public ownerPlasma;
    address public ethUSDExchangeContract;
    address public twoKeyAcquisitionCampaign;

    uint256 campaignStartTime; // Time when campaign start
    uint256 campaignEndTime; // Time when campaign ends

    uint minContributionETHorFiatCurrency;
    uint maxContributionETHorFiatCurrency;
    uint256 pricePerUnitInETHWeiOrUSD; // There's single price for the unit ERC20 (Should be in WEI)
    uint unit_decimals; // ERC20 selling data

    string public publicMetaHash; // Ipfs hash of json campaign object
    string privateMetaHash; // Ipfs hash of json sensitive (contractor) information

    uint maxConverterBonusPercent;
    string public currency;

    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    constructor(
        uint _minContribution,
        uint _maxContribution,
        uint _pricePerUnitInETHWeiOrUSD,
        uint _campaignStartTime,
        uint _campaignEndTime,
        uint _maxConverterBonusPercent,
        string _currency,
        address _ethUsdExchangeContract,
        address _assetContractERC20,
        address _twoKeyRegistry
    ) public {
        contractor = msg.sender;
        minContributionETHorFiatCurrency = _minContribution;
        maxContributionETHorFiatCurrency = _maxContribution;
        pricePerUnitInETHWeiOrUSD = _pricePerUnitInETHWeiOrUSD;
        campaignStartTime = _campaignStartTime;
        campaignEndTime = _campaignEndTime;
        maxConverterBonusPercent = _maxConverterBonusPercent;
        currency = _currency;
        ethUSDExchangeContract = _ethUsdExchangeContract;
        twoKeyRegistry = _twoKeyRegistry;
        unit_decimals = IERC20(_assetContractERC20).decimals();
        ownerPlasma = plasmaOf(msg.sender);
    }

    /**
     * @notice Requirement for the checking if the campaign is active or not
     */
    function requirementIsOnActive() public view returns (bool) {
        if(block.timestamp >= campaignStartTime && block.timestamp <= campaignEndTime) {
            return true;
        }
        return false;
    }

    function setTwoKeyAcquisitionCampaignContract(address _acquisitionCampaignAddress) public {
        require(twoKeyAcquisitionCampaign == address(0)); // Means it can be set only once
        twoKeyAcquisitionCampaign = _acquisitionCampaignAddress;
    }

    /**
     * @notice internal function to validate the request is proper
     * @param msgValue is the value of the message sent
     * @dev validates if msg.Value is in interval of [minContribution, maxContribution]
     */
    function requirementForMsgValue(uint msgValue) public view returns (bool) {
        if(keccak256(currency) == keccak256('ETH')) {
            require(msgValue >= minContributionETHorFiatCurrency);
            require(msgValue <= maxContributionETHorFiatCurrency);
        } else {
            uint val;
            bool flag;
            (val, flag,,) = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getFiatCurrencyDetails(currency);
            if(flag) {
                require((msgValue * val).div(10**18) >= minContributionETHorFiatCurrency); //converting ether to fiat
                require((msgValue * val).div(10**18) <= maxContributionETHorFiatCurrency); //converting ether to fiat
            } else {
                require(msgValue >= (val * minContributionETHorFiatCurrency).div(10**18)); //converting fiat to ether
                require(msgValue <= (val * maxContributionETHorFiatCurrency).div(10**18)); //converting fiat to ether
            }
        }
        return true;
    }

    /**
     * @notice Function which will calculate the base amount, bonus amount
     * @param conversionAmountETHWeiOrFiat is amount of eth in conversion
     * @return tuple containing (base,bonus)
     */
    function getEstimatedTokenAmount(uint conversionAmountETHWeiOrFiat, bool isFiatConversion) public view returns (uint, uint) {
        uint value = pricePerUnitInETHWeiOrUSD;
        uint baseTokensForConverterUnits;
        uint bonusTokensForConverterUnits;
        if(isFiatConversion == true) {
            baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.div(value);
            bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
        } else {
            if(keccak256(currency) != keccak256('ETH')) {
                uint rate;
                bool flag;
                (rate,flag,,) = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getFiatCurrencyDetails(currency);
                if(flag) {
                    conversionAmountETHWeiOrFiat = (conversionAmountETHWeiOrFiat.mul(rate)).div(10 ** 18); //converting eth to $wei
                } else {
                    value = (value.mul(rate)).div(10 ** 18); //converting dollar wei to eth
                }
            }
        }

        baseTokensForConverterUnits = conversionAmountETHWeiOrFiat.mul(10 ** unit_decimals).div(value);
        bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
        return (baseTokensForConverterUnits, bonusTokensForConverterUnits);
    }

    /**
     * @notice Function to update MinContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new value we are going to set for minContributionETH
     */
    function updateMinContributionETHOrUSD(uint value) public onlyContractor {
        minContributionETHorFiatCurrency = value;
        //        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /**
     * @notice Function to update maxContributionETH
     * @dev only Contractor can call this method, otherwise it will revert - emits Event when updated
     * @param value is the new maxContribution value
     */
    function updateMaxContributionETHorUSD(uint value) external onlyContractor {
        maxContributionETHorFiatCurrency = value;
        //        twoKeyEventSource.updatedData(block.timestamp, value, "Updated maxContribution");
    }

    /**
     * @notice Function to update /set publicMetaHash
     * @dev only Contractor can call this function, otherwise it will revert - emits Event when set/updated
     * @param value is the value for the publicMetaHash
     */
    function updateOrSetIpfsHashPublicMeta(string value) public onlyContractor {
        publicMetaHash = value;
        //        twoKeyEventSource.updatedPublicMetaHash(block.timestamp, value);
    }


    /**
     * @notice Setter for privateMetaHash
     * @dev only Contractor can call this method, otherwise function will revert
     * @param _privateMetaHash is string representation of private metadata hash
     */
    function setPrivateMetaHash(string _privateMetaHash) public onlyContractor {
        privateMetaHash = _privateMetaHash;
    }

    /**
     * @notice Getter for privateMetaHash
     * @dev only Contractor can call this method, otherwise function will revert
     * @return string representation of private metadata hash
     */
    function getPrivateMetaHash() public view onlyContractor returns (string) {
        return privateMetaHash;
    }

    /**
     * @notice Get all constants from the contract
     * @return all constants from the contract
     */
    function getConstantInfo() public view returns (uint,uint,uint,uint,uint,uint,uint) {
        return (
        campaignStartTime,
        campaignEndTime,
        minContributionETHorFiatCurrency,
        maxContributionETHorFiatCurrency,
        unit_decimals,
        pricePerUnitInETHWeiOrUSD,
        maxConverterBonusPercent);
    }

    /**
     * @notice Function to get suepr statistics
     */
    function getSuperStatistics(address _user, bool plasma) public view returns (bytes32, bytes32, bytes32, bool, bytes, address) {
        bytes32 username;
        bytes32 fullName;
        bytes32 email;
        address eth_address;
        eth_address = _user;
        if (plasma) {
            (eth_address) = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_user);
        }

        (username,fullName,email) = ITwoKeyReg(twoKeyRegistry).getUserData(eth_address);
        bool isJoined = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getAddressJoinedStatus(_user);
        bytes memory stats = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaign).getAddressStatistic(_user, plasma);
        return (username, fullName, email, isJoined, stats, eth_address);
    }

    function getReferrers(address customer, address acquisitionCampaignContract) public view returns (address[]) {
        address influencer = plasmaOf(customer);
        uint n_influencers = 0;
        while (true) {
            influencer = plasmaOf(IAcquisitionGetReceivedFrom(acquisitionCampaignContract).getReceivedFrom(influencer));
            if (influencer == plasmaOf(contractor)) {
                break;
            }
            n_influencers++;
        }
        address[] memory influencers = new address[](n_influencers);
        influencer = plasmaOf(customer);
        while (n_influencers > 0) {
            influencer = plasmaOf(IAcquisitionGetReceivedFrom(acquisitionCampaignContract).getReceivedFrom(influencer));
            n_influencers--;
            influencers[n_influencers] = influencer;
        }
        return influencers; //reverse ordered array
    }

    /**
     * @notice Function to determine plasma address of ethereum address
     * @param me is the address (ethereum) of the user
     * @return an address
     */
    function plasmaOf(address me) public view returns (address) {
        if (twoKeyRegistry == address(0)) {
            me;
        }
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
    function ethereumOf(address me) public view returns (address) {
        if (twoKeyRegistry == address(0)) {
            return me;
        }
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

}
