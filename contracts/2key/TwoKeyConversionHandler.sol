pragma solidity ^0.4.24;
import '../openzeppelin-solidity/contracts/ownership/Ownable.sol';
import "./TwoKeyTypes.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "./RBACWithAdmin.sol";
import "./TwoKeyConversionStates.sol";
import "./TwoKeyLockupContract.sol";
import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TwoKeyConverterStates.sol";



// adapted from: 
// https://openzeppelin.org/api/docs/crowdsale_validation_WhitelistedCrowdsale.html

contract TwoKeyConversionHandler is TwoKeyTypes, TwoKeyConversionStates {

    using SafeMath for uint256;

    mapping(address => Conversion) public conversions;

    // Mapping where we will store as the key state of conversion, and as value, there'll be all converters which conversions are in that state
    mapping(bytes32 => address[]) conversionStateToConverters;

    // Mapping where we will store converter address as the key, and as the value we will save the state of his conversion
    mapping(address => ConversionState) converterToConversionState;

    mapping(address => address[]) converterToLockupContracts;

    address[] allLockUpContracts;

    address twoKeyAcquisitionCampaignERC20;
    address moderator;
    address contractor;

    address assetContractERC20;
    string assetSymbol;
    uint assetUnitDecimals;

    uint tokenDistributionDate; // January 1st 2019
    uint maxDistributionDateShiftInDays; // 180 days
    uint bonusTokensVestingMonths; // 6 months
    uint bonusTokensVestingStartShiftInDaysFromDistributionDate; // 180 days



    /// Structure which will represent conversion
    struct Conversion {
        address contractor; // Contractor (creator) of campaign
        uint256 contractorProceedsETHWei; // How much contractor will receive for this conversion
        address converter; // Converter is one who's buying tokens
        ConversionState state;
        string assetSymbol; // Name of ERC20 token we're selling in our campaign (we can get that from contract address)
        address assetContractERC20; // Address of ERC20 token we're selling in our campaign
        uint256 conversionAmount; // Amount for conversion (In ETH)
        uint256 maxReferralRewardETHWei;
        uint256 moderatorFeeETHWei;
        uint256 baseTokenUnits;
        uint256 bonusTokenUnits;
        CampaignType campaignType; // Enumerator representing type of campaign (This one is however acquisition)
        uint256 conversionCreatedAt; // When conversion is created
        uint256 conversionExpiresAt; // When conversion expires
    }

    /// @notice Modifier which allows only TwoKeyAcquisitionCampaign to issue calls
    modifier onlyTwoKeyAcquisitionCampaign() {
        require(msg.sender == address(twoKeyAcquisitionCampaignERC20));
        _;
    }

    modifier onlyContractorOrModerator {
        require(msg.sender == address(contractor) || msg.sender == address(moderator));
        _;
    }


    modifier onlyApprovedConverter() {
        require(converterToConversionState[msg.sender] == ConversionState.APPROVED);
        _;
    }


    constructor(uint _tokenDistributionDate, // January 1st 2019
        uint _maxDistributionDateShiftInDays, // 180 days
        uint _bonusTokensVestingMonths, // 6 months
        uint _bonusTokensVestingStartShiftInDaysFromDistributionDate) public {
        tokenDistributionDate = _tokenDistributionDate;
        maxDistributionDateShiftInDays = _maxDistributionDateShiftInDays;
        bonusTokensVestingMonths = _bonusTokensVestingMonths;
        bonusTokensVestingStartShiftInDaysFromDistributionDate = _bonusTokensVestingStartShiftInDaysFromDistributionDate;
    }

    /// @notice Method which will be called inside constructor of TwoKeyAcquisitionCampaignERC20
    /// @param _twoKeyAcquisitionCampaignERC20 is the address of TwoKeyAcquisitionCampaignERC20 contract
    /// @param _moderator is the address of the moderator
    /// @param _contractor is the address of the contractor
    function setTwoKeyAcquisitionCampaignERC20(address _twoKeyAcquisitionCampaignERC20, address _moderator, address _contractor, address _assetContractERC20, string _assetSymbol) public {
        require(twoKeyAcquisitionCampaignERC20 == address(0));
        twoKeyAcquisitionCampaignERC20 = _twoKeyAcquisitionCampaignERC20;
        moderator = _moderator;
        contractor = _contractor;
        assetContractERC20 =_assetContractERC20;
        assetSymbol = _assetSymbol;
    }


    /// @notice Function which checks if converter has converted
    /// @dev will throw if not
    /// @param converterAddress is the address of converter
    function isConversionExecuted(address converterAddress) public view {
        Conversion memory c = conversions[converterAddress];
        require(c.state != ConversionState.FULFILLED);
        require(c.state != ConversionState.CANCELLED);
    }


    /// @notice Support function to create conversion
    /// @dev This function can only be called from TwoKeyAcquisitionCampaign contract address
    /// @param _contractor is the address of campaign contractor
    /// @param _contractorProceeds is the amount which goes to contractor
    /// @param _converterAddress is the address of the converter
    /// @param _conversionAmount is the amount for conversion in ETH
    /// @param expiryConversion is the length of conversion
    function supportForCreateConversion(
            address _contractor,
            uint256 _contractorProceeds,
            address _converterAddress,
            uint256 _conversionAmount,
            uint256 _maxReferralRewardETHWei,
            uint256 _moderatorFeeETHWei,
            uint256 baseTokensForConverterUnits,
            uint256 bonusTokensForConverterUnits,
            uint256 expiryConversion) public onlyTwoKeyAcquisitionCampaign {
        // these are going to be global variables

        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress,
            ConversionState.PENDING, assetSymbol, assetContractERC20, _conversionAmount,
            _maxReferralRewardETHWei, _moderatorFeeETHWei, baseTokensForConverterUnits,
            bonusTokensForConverterUnits, CampaignType.CPA_FUNGIBLE,
            now, now + expiryConversion * (1 hours)); // commented *(1hours)

        conversions[_converterAddress] = c;
        converterToConversionState[_converterAddress] = ConversionState.PENDING;
        conversionStateToConverters[bytes32("PENDING")].push(_converterAddress);
    }

    /// @notice Function to encode provided parameters into bytes
    /// @param converter is address of converter
    /// @param conversionCreatedAt is timestamp when conversion is created
    /// @param conversionAmountETH is the amount of conversion in ETH
    /// @return bytes containing all this data concatenated and encoded into hex
    function encodeParams(address converter, uint conversionCreatedAt, uint conversionAmountETH) public pure returns(bytes) {
        return abi.encodePacked(converter, conversionCreatedAt, conversionAmountETH);
    }

    function getEncodedConversion(address converter) public view returns (bytes) {
        Conversion memory _conversion = conversions[converter];
        bytes memory encoded = encodeParams(_conversion.converter, _conversion.conversionCreatedAt, _conversion.conversionAmount);
        return encoded;
    }


    function executeConversion(address _converter) public onlyApprovedConverter {
        isConversionExecuted(_converter);
        performConversion(_converter);
        moveFromApprovedToFulfilledState(_converter);
    }

    function performConversion(address _converter) internal {
        Conversion memory conversion = conversions[_converter];

        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateRefchainRewards(conversion.maxReferralRewardETHWei, _converter);

        // update moderator balances
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateModeratorBalanceETHWei(conversion.moderatorFeeETHWei);


        TwoKeyLockupContract lockupContract = new TwoKeyLockupContract(bonusTokensVestingStartShiftInDaysFromDistributionDate, bonusTokensVestingMonths, tokenDistributionDate, maxDistributionDateShiftInDays,
            conversion.baseTokenUnits, conversion.bonusTokenUnits, _converter, conversion.contractor, twoKeyAcquisitionCampaignERC20, assetContractERC20);

        allLockUpContracts.push(address(lockupContract));

        uint totalUnits = conversion.baseTokenUnits + conversion.bonusTokenUnits;
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).moveFungibleAsset(address(lockupContract), totalUnits);

        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateContractorProceeds(conversion.contractorProceedsETHWei);
        conversion.state = ConversionState.FULFILLED;
        conversions[_converter] = conversion;
        converterToLockupContracts[_converter].push(lockupContract);
    }

    /// @notice Function to convert converter state to it's bytes representation (Maybe we don't even need it)
    /// @param state is conversion state
    /// @return bytes32 (hex) representation of state
    function convertConverterStateToBytes(ConversionState state) public view returns (bytes32) {
        if(ConversionState.APPROVED == state) {
            return bytes32("APPROVED");
        }
        if(ConversionState.REJECTED == state) {
            return bytes32("REJECTED");
        }
        if(ConversionState.CANCELLED == state) {
            return bytes32("CANCELLED");
        }
        if(ConversionState.PENDING == state) {
            return bytes32("PENDING");
        }
        if(ConversionState.FULFILLED == state) {
            return bytes32("FULFILLED");
        }
    }


    /// @notice Function to check whether converter is approved or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterApproved(address _converter) public onlyContractorOrModerator view  returns (bool) {
        if(converterToConversionState[_converter] == ConversionState.APPROVED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is rejected or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterRejected(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToConversionState[_converter] == ConversionState.REJECTED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is cancelled or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterCancelled(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToConversionState[_converter] == ConversionState.CANCELLED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is fulfilled or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterFulfilled(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToConversionState[_converter] == ConversionState.FULFILLED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is pending or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterPending(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToConversionState[_converter] == ConversionState.PENDING) {
            return true;
        }
        return false;
    }


    /// @notice Function to get all pending converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of pending converter addresses
    function getAllPendingConverters() public view onlyContractorOrModerator returns (address[]) {
        return (conversionStateToConverters[bytes32("PENDING")]);
    }

    /// @notice Function to get all rejected converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of rejected converter addresses
    function getAllRejectedConverters() public view onlyContractorOrModerator returns(address[]) {
        return conversionStateToConverters[bytes32("REJECTED")];
    }


    /// @notice Function to get all approved converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of approved converter addresses
    function getAllApprovedConverters() public view onlyContractorOrModerator returns(address[]) {
        return conversionStateToConverters[bytes32("APPROVED")];
    }


    /// @notice Function to get all cancelled converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of cancelled converter addresses
    function getAllCancelledConverters() public view onlyContractorOrModerator returns(address[]) {
        return conversionStateToConverters[bytes32("CANCELLED")];
    }


    /// @notice Function to get all fulfilled converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of fulfilled converter addresses
    function getAllFulfilledConverters() public view onlyContractorOrModerator returns(address[]) {
        return conversionStateToConverters[bytes32("FULFILLED")];
    }


    /// @notice Function to get array of lockup contract addresses for converter
    /// @dev only contractor or moderator can call this function
    /// @param _converter is the address of converter
    /// @return array of addresses
    function getLockupContractsForConverter(address _converter) public view onlyContractorOrModerator returns (address[]){
        return converterToLockupContracts[_converter];
    }


    /// @notice Function to move converter address from stateA to stateB
    /// @param _converter is the address of converter
    /// @param destinationState is the state we'd like to move converter to
    function moveFromStateAToStateB(address _converter, bytes32 destinationState) internal {
        ConversionState state = converterToConversionState[_converter];
        bytes32 key = convertConverterStateToBytes(state);
        address[] memory pending = conversionStateToConverters[key];
        for(uint i=0; i< pending.length; i++) {
            if(pending[i] == _converter) {
                conversionStateToConverters[destinationState].push(_converter);
                pending[i] = pending[pending.length-1];
                delete pending[pending.length-1];
                conversionStateToConverters[key] = pending;
                conversionStateToConverters[key].length--;
                break;
            }
        }
    }


    /// @notice Function where we can change state of converter to Approved
    /// @dev Converter can only be approved if his previous state is pending or rejected
    /// @param _converter is the address of converter
    function moveFromPendingOrRejectedToApprovedState(address _converter) private {
        bytes32 destination = bytes32("APPROVED");
        moveFromStateAToStateB(_converter, destination);
        converterToConversionState[_converter] = ConversionState.APPROVED;
    }


    /// @notice Function where we can change state of converter to Approved
    /// @dev Converter can only be approved if his previous state is pending or rejected
    /// @param _converter is the address of converter
    function moveFromPendingOrRejectedToCancelledState(address _converter) private {
        bytes32 destination = bytes32("CANCELLED");
        moveFromStateAToStateB(_converter, destination);
        converterToConversionState[_converter] = ConversionState.CANCELLED;
    }


    /// @notice Function where we're going to move state of conversion from pending to rejected
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromPendingToRejectedState(address _converter) private {
        bytes32 destination = bytes32("REJECTED");
        moveFromStateAToStateB(_converter, destination);
        converterToConversionState[_converter] = ConversionState.REJECTED;
    }

    /// @notice Function where we're going to move state of conversion from approved to fulfilled
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromApprovedToFulfilledState(address _converter) private {
        bytes32 destination = bytes32("FULFILLED");
        moveFromStateAToStateB(_converter, destination);
        converterToConversionState[_converter] = ConversionState.FULFILLED;
    }


    /// @notice Function where we are approving converter
    /// @dev only moderator or contractor can call this method
    /// @param _converter is the address of converter
    function approveConverter(address _converter) public onlyContractorOrModerator {
        require(converterToConversionState[_converter] == ConversionState.PENDING || converterToConversionState[_converter] == ConversionState.REJECTED);
        moveFromPendingOrRejectedToApprovedState(_converter);
    }


    /// @notice Function where we can reject converter
    /// @dev only moderator or contractor can call this function
    /// @param _converter is the address of converter
    function rejectConverter(address _converter) public onlyContractorOrModerator  {
        require(converterToConversionState[_converter] == ConversionState.PENDING);
        moveFromPendingToRejectedState(_converter);
    }


    /// @notice Function where contractor or moderator can cancel the converter
    function cancelConverter() public {
        require(converterToConversionState[msg.sender] == ConversionState.REJECTED ||
        converterToConversionState[msg.sender] == ConversionState.PENDING);
        moveFromPendingOrRejectedToCancelledState(msg.sender);

        Conversion memory conversion = conversions[msg.sender];
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).sendBackEthWhenConversionCancelled(msg.sender, conversion.conversionAmount);
    }


    function cancelAndRejectContract() public onlyTwoKeyAcquisitionCampaign {
        for(uint i=0; i<allLockUpContracts.length; i++) {
            TwoKeyLockupContract(allLockUpContracts[i]).cancelCampaignAndGetBackTokens(assetContractERC20);
        }
    }

}