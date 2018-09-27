pragma solidity ^0.4.24;


import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./TwoKeyTypes.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "./RBACWithAdmin.sol";
import "./TwoKeyConversionStates.sol";


// adapted from: 
// https://openzeppelin.org/api/docs/crowdsale_validation_WhitelistedCrowdsale.html

//TODO: replace Ownable with RBAC
contract TwoKeyWhitelisted is TwoKeyTypes, TwoKeyConversionStates {
    //TODO: Add getter for conversions with modifier only
    //TODO: add separated lists of approved, pending, rejected, cancelled
    //TODO: See if possible to jsonify conversion into string
    /*
      TODO: Add approve function functions to move conversions from
                pending -> rejected
                pending -> approved
                pending -> canceled
                pending -> expired (?)
                rejected -> approved
                This functions (ending approved) can then call the executeConversion in the contract
    */
    // Mapping conversion to converter address
    mapping(address => Conversion) public conversions;

    // converter --> string (json) of static fields which doesn't change
    // string (json) of static fields which doesn't change --> object containing all the fields

    address twoKeyAcquisitionCampaignERC20;
    address moderator;
    address contractor;

    address assetContractERC20;
    string assetSymbol;
    uint assetUnitDecimals;



    bytes[] hashesOfPendingConversions;
    bytes[] hashesOfApprovedConversions;
    bytes[] hashesOfRejectedConversions;
    bytes[] hashesOfExpiredConversions;



    function setTwoKeyAcquisitionCampaignERC20(address _twoKeyAcquisitionCampaignERC20, address _moderator, address _contractor) public {
        require(twoKeyAcquisitionCampaignERC20 == address(0));
        twoKeyAcquisitionCampaignERC20 = _twoKeyAcquisitionCampaignERC20;
        moderator = _moderator;
        contractor = _contractor;
        // get asset name, address, price, etc all we need
    }
    /// Structure which will represent conversion
    /// TODO: add to conversion object : internalId(uint) (comes from frontend) (can be set after)
    struct Conversion {
//        uint internalId; // internal id of conversion
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
        uint256 conversionCreatedAt; // When conversion is created
        uint256 conversionExpiresAt; // When conversion expires
    }

    modifier onlyTwoKeyAcquisitionCampaign() {
        require(msg.sender == twoKeyAcquisitionCampaignERC20);
        _;
    }


    mapping(address => bool) public whitelistedReferrer;
    mapping(address => bool) public whitelistedConverter;


    constructor() public {

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
    function addToWhitelistReferrer(address _beneficiary) public {
        whitelistedReferrer[_beneficiary] = true;
    }
    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelis
     */
    function addManyToWhitelistReferrer(address[] _beneficiaries) public {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistedReferrer[_beneficiaries[i]] = true;
        }
    }
    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelistReferrer(address _beneficiary) public {
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
    function addToWhitelistConverter(address _beneficiary) public {
        whitelistedConverter[_beneficiary] = true;
    }
    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelis
     */
    function addManyToWhitelistConverter(address[] _beneficiaries) public {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelistedConverter[_beneficiaries[i]] = true;
        }
    }
    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelistConverter(address _beneficiary) public {
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

    function supportForCanceledEscrow(address _converter) public onlyTwoKeyAcquisitionCampaign returns (uint256){
        Conversion memory c = conversions[_converter];
        c.isCancelledByConverter = true;
        conversions[_converter] = c;

        return (c.contractorProceeds);
    }

    function supportForCancelAssetTwoKey(address _converter) public onlyTwoKeyAcquisitionCampaign view{
        Conversion memory c = conversions[_converter];
        require(!c.isCancelledByConverter && !c.isFulfilled && !c.isRejectedByModerator);
    }

    function supportForExpireEscrow(address _converter) public onlyTwoKeyAcquisitionCampaign view {
        Conversion memory c = conversions[_converter];
        require(!c.isCancelledByConverter && !c.isFulfilled && !c.isRejectedByModerator);
        require(now > c.conversionExpiresAt);
    }

    function supportForCreateConversion(
            address _contractor,
            uint256 _contractorProceeds,
            address _converterAddress,
//            bool _isFulfilled,
//            bool _isCancelledByConverter,
//            bool _isRejectedByModerator,
//            string _assetSymbol,
//            address _assetContractERC20,
            uint256 _conversionAmount,
            uint256 expiryConversion) public onlyTwoKeyAcquisitionCampaign {
        // these are going to be global variables
        address _assetContractERC20 = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).getAssetContractAddress();
        string memory _assetSymbol = ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).getSymbol();
        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress, false, false, false, _assetSymbol, _assetContractERC20, _conversionAmount, CampaignType.CPA_FUNGIBLE, now, now + expiryConversion * (1 hours));
        conversions[_converterAddress] = c;
    }

    function hashValues(address converter, uint conversionCreatedAt, uint conversionAmountETHWei) public view returns (bytes32) {
        bytes32 hash = sha256(converter, conversionCreatedAt,conversionAmountETHWei);
        return hash;
    }

    /*
    Add mapping address => bytes32[] so we can know all campaigns for the user
    */






}