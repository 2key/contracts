pragma solidity ^0.4.24;


import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./TwoKeyTypes.sol";


// adapted from: 
// https://openzeppelin.org/api/docs/crowdsale_validation_WhitelistedCrowdsale.html

contract TwoKeyWhitelisted is Ownable, TwoKeyTypes {


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

    // Mapping conversion to user address
    mapping(address => Conversion) public conversions;

    mapping(address => bool) public whitelist;

    constructor() Ownable() public {

    }

    function isWhitelisted(address _beneficiary) public view returns(bool) {
        return(whitelist[_beneficiary]);
    }

    /*
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
     * @param _beneficiaries Addresses to be added to the whitelis
     */
    function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
          whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */

    function removeFromWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = false;
    }
}