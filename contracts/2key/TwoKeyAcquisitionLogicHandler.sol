pragma solidity ^0.4.24;
import "../interfaces/ITwoKeyExchangeRateContract.sol";
import "../interfaces/IERC20.sol";
import "../openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @author Nikola Madjarevic
 * Created at 1/15/19
 */
contract TwoKeyAcquisitionLogicHandler {

    using SafeMath for uint256;

    address contractor;
    address ethUSDExchangeContract;

    uint minContributionETHorFiatCurrency;
    uint maxContributionETHorFiatCurrency;
    uint256 pricePerUnitInETHWeiOrUSD; // There's single price for the unit ERC20 (Should be in WEI)
    uint unit_decimals; // ERC20 selling data

    string public publicMetaHash; // Ipfs hash of json campaign object
    string privateMetaHash; // Ipfs hash of json sensitive (contractor) information

    string public currency;

    modifier onlyContractor {
        require(msg.sender == contractor);
        _;
    }

    constructor(
        uint _minContribution,
        uint _maxContribution,
        uint _pricePerUnitInETHWeiOrUSD,
        string _currency,
        address _ethUsdExchangeContract,
        address _assetContractERC20,
        string _publicMetaHash,
        string _privateMetaHash
    ) public {
        contractor = msg.sender;
        minContributionETHorFiatCurrency = _minContribution;
        maxContributionETHorFiatCurrency = _maxContribution;
        pricePerUnitInETHWeiOrUSD = _pricePerUnitInETHWeiOrUSD;
        currency = _currency;
        ethUSDExchangeContract = _ethUsdExchangeContract;
        unit_decimals = IERC20(_assetContractERC20).decimals();
        publicMetaHash = _publicMetaHash;
        privateMetaHash = _privateMetaHash;
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
     * @param conversionAmountETHWei is amount of eth in conversion
     * @return tuple containing (base,bonus)
     */
    function getEstimatedTokenAmount(uint conversionAmountETHWei, uint maxConverterBonusPercent) public view returns (uint, uint) {
        uint value = pricePerUnitInETHWeiOrUSD;
        if(keccak256(currency) != keccak256('ETH')) {
            uint rate;
            bool flag;
            (rate,flag,,) = ITwoKeyExchangeRateContract(ethUSDExchangeContract).getFiatCurrencyDetails(currency);
            if(flag) {
                conversionAmountETHWei = (conversionAmountETHWei * rate).div(10 ** 18); //converting eth to $wei
            } else {
                value = (value * rate).div(10 ** 18); //converting dollar wei to eth
            }
        }
        uint baseTokensForConverterUnits = conversionAmountETHWei.mul(10 ** unit_decimals).div(value);
        uint bonusTokensForConverterUnits = baseTokensForConverterUnits.mul(maxConverterBonusPercent).div(100);
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
}
