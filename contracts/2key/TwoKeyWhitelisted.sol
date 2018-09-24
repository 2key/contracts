pragma solidity ^0.4.24;


import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./TwoKeyTypes.sol";


// adapted from: 
// https://openzeppelin.org/api/docs/crowdsale_validation_WhitelistedCrowdsale.html

contract TwoKeyWhitelisted is Ownable, TwoKeyTypes {

    // Mapping conversion to user address
    mapping(address => Conversion) public conversions;

    /// Structure which will represent conversion
    struct Conversion {
        address contractor; // Contractor (creator) of campaign
        uint256 contractorProceeds; // How much contractor will receive for this conversion
        address converter; // Converter is one who's buying tokens
        bool isFulfilled; // Conversion finished (processed)
        bool isCancelledByConverter; // Canceled by converter
        bool isRejectedByModerator; // Rejected by moderator
        string assetSymbol; // Name of ERC20 token we're selling in our campaign (we can get that from contract address)
        address assetContractERC20; // Address of ERC20 token we're selling in our campaign
        uint256 conversionAmount; // Amount for conversion (In ETH)
        CampaignType campaignType; // Enumerator representing type of campaign (This one is however acquisition)
        uint256 campaignStartTime; // When campaign actually starts
        uint256 campaignEndTime; // When campaign actually ends
    }

    modifier onlyTwoKeyAcquisitionCampaign() {
        _;
    }


    mapping(address => bool) public whitelistedReferrer;
    mapping(address => bool) public whitelistedConverter;


    constructor() Ownable() public {

    }

    /*
    ==============================CONVERTER WHITELIST FUNCTIONS=========================================================
    */
    function isWhitelistedReferrer(address _beneficiary) public view returns(bool) {
        return(whitelistedReferrer[_beneficiary]);
    }

    /*
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelistReferrer(address _beneficiary) public onlyOwner {
        whitelistedReferrer[_beneficiary] = true;
    }
    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelis
     */
    function addManyToWhitelistReferrer(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistedReferrer[_beneficiaries[i]] = true;
        }
    }
    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelistReferrer(address _beneficiary) public onlyOwner {
        whitelistedReferrer[_beneficiary] = false;
    }

    /*
    ===========================CONVERTER WHITELIST FUNCTIONS============================================================
    */

    function isWhitelistedConverter(address _beneficiary) public view returns(bool) {
        return(whitelistedConverter[_beneficiary]);
    }

    /*
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelistConverter(address _beneficiary) public onlyOwner {
        whitelistedConverter[_beneficiary] = true;
    }
    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelis
     */
    function addManyToWhitelistConverter(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistedConverter[_beneficiaries[i]] = true;
        }
    }
    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelistConverter(address _beneficiary) public onlyOwner {
        whitelistedConverter[_beneficiary] = false;
    }

    /*
    ====================================================================================================================
    */

    /// @notice Will throw if not
    function didConverterConvert() public view {
        Conversion memory c = conversions[msg.sender];
        require(!c.isFulfilled && !c.isCancelledByConverter);
    }

    /*
    ====================================================================================================================
    */

    // TODO: Here we'll add modifier so all this methods can be called only by twoKeyAcquisitionCampaign
    function supportForCanceledEscrow(address _converter) public returns (uint256){
        Conversion memory c = conversions[_converter];
        c.isCancelledByConverter = true;
        conversions[_converter] = c;

        return (c.contractorProceeds);
    }

    function supportForCancelAssetTwoKey(address _converter) public view{
        Conversion memory c = conversions[_converter];
        require(!c.isCancelledByConverter && !c.isFulfilled && !c.isRejectedByModerator);
    }

    function supportForExpireEscrow(address _converter) public view {
        Conversion memory c = conversions[_converter];
        require(!c.isCancelledByConverter && !c.isFulfilled && !c.isRejectedByModerator);
        require(now > c.campaignEndTime);
    }


    function createConversion(
            address _contractor,
            uint256 _contractorProceeds,
            address _converterAddress,
            bool _isFulfilled,
            bool _isCancelledByConverter,
            bool _isRejectedByModerator,
            string _assetSymbol,
            address _assetContractERC20,
            uint256 _conversionAmount,
            uint256 expiryConversion) public {

        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress, _isFulfilled,
            _isCancelledByConverter, _isRejectedByModerator, _assetSymbol, _assetContractERC20, _conversionAmount, CampaignType.CPA_FUNGIBLE, now, now + expiryConversion * 1 days);
        conversions[_converterAddress] = c;
    }



}