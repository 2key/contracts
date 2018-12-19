pragma solidity ^0.4.24;
import "./TwoKeyTypes.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignERC20.sol";
import "./TwoKeyConversionAndConverterStates.sol";
import "./TwoKeyLockupContract.sol";
import "../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../interfaces/IERC20.sol";

/**
 * @notice Contract to handle logic related for Acquisition
 * @dev There will be 1 conversion handler per Acquisition Campaign
 * @author Nikola Madjarevic
 */
contract TwoKeyConversionHandler is TwoKeyTypes, TwoKeyConversionAndConverterStates {

    using SafeMath for uint256;
    uint numberOfConversions;
    Conversion[] public conversions;
    mapping(address => uint[]) converterToHisConversions;

    //State to all converters in that state
    mapping(bytes32 => address[]) stateToConverter;

    //Converter to his state
    mapping(address => ConverterState) converterToState;

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
        uint256 conversionAmount; // Amount for conversion (In ETH)
        uint256 maxReferralRewardETHWei;
        uint256 moderatorFeeETHWei;
        uint256 baseTokenUnits;
        uint256 bonusTokenUnits;
        CampaignType campaignType; // Enumerator representing type of campaign (This one is however acquisition)
        uint256 conversionCreatedAt; // When conversion is created
        uint256 conversionExpiresAt; // When conversion expires
        bool isAnonymousContractor;
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
        require(converterToState[msg.sender] == ConverterState.APPROVED);
        _;
    }


    /**
     * @notice Contstructor of the conversion handler contract
     * @param _tokenDistributionDate is the date of token distribution
     * @param _maxDistributionDateShiftInDays is the maximum distribution shift in days
     * @param _bonusTokensVestingMonths is the number of bonus token vesting months
     * @param _bonusTokensVestingStartShiftInDaysFromDistributionDate is
     */
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
    function isConversionNotExecuted(uint _conversionId) public view returns (bool) {
        Conversion memory c = conversions[_conversionId];
        require(c.state == ConversionState.PENDING_APPROVAL || c.state == ConversionState.APPROVED);
        return true;
    }

    /**
     * @notice Determine the state of conversion based on converter address
     * @param _converterAddress is the address of converter
     * @return state of conversion (enum)
     */
    function determineConversionState(address _converterAddress) private view returns (ConversionState) {
        ConversionState state = ConversionState.PENDING_APPROVAL;
        if(converterToState[_converterAddress] == ConverterState.APPROVED) {
            state = ConversionState.APPROVED;
        } else if (converterToState[_converterAddress] == ConverterState.REJECTED) {
            state = ConversionState.REJECTED;
        }
        return state;
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

        ConversionState state = determineConversionState(_converterAddress);
        Conversion memory c = Conversion(_contractor, _contractorProceeds, _converterAddress,
            state ,_conversionAmount, _maxReferralRewardETHWei, _moderatorFeeETHWei, baseTokensForConverterUnits,
            bonusTokensForConverterUnits, CampaignType.CPA_FUNGIBLE,
            now, now + expiryConversion * (1 hours), false);

        conversions.push(c);
        converterToHisConversions[msg.sender].push(numberOfConversions);
        numberOfConversions++;

        if(converterToState[_converterAddress] == ConverterState.NOT_EXISTING) {
            converterToState[_converterAddress] = ConverterState.PENDING_APPROVAL;
            stateToConverter[bytes32("PENDING_APPROVAL")].push(_converterAddress);
        }
    }


    /**
     * @notice Function to execute conversion
     * @param _conversionId is the id of the conversion
     * @dev this can be called only by approved converter
     */
    function executeConversion(uint _conversionId) external onlyApprovedConverter {
        require(isConversionNotExecuted(_conversionId));
        //        bool flag = false;
        //        for(uint i=0; i<converterToHisConversions[msg.sender].length; i++) {
        //            if(converterToHisConversions[msg.sender][i] == _conversionId) {
        //                flag = true;
        //            }
        //        }
        //        require(flag);
        performConversion(_conversionId);
    }


    /**
     * @notice Function to perform all the logic which has to be done when we're performing conversion
     * @param _conversionId is the id
     */
    function performConversion(uint _conversionId) internal {
        Conversion memory conversion = conversions[_conversionId];

        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateRefchainRewards(conversion.maxReferralRewardETHWei, conversion.converter);

        // update moderator balances
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateModeratorBalanceETHWei(conversion.moderatorFeeETHWei);


        TwoKeyLockupContract lockupContract = new TwoKeyLockupContract(bonusTokensVestingStartShiftInDaysFromDistributionDate, bonusTokensVestingMonths, tokenDistributionDate, maxDistributionDateShiftInDays,
            conversion.baseTokenUnits, conversion.bonusTokenUnits, conversion.converter, conversion.contractor, twoKeyAcquisitionCampaignERC20, assetContractERC20);

        allLockUpContracts.push(address(lockupContract));

        uint totalUnits = conversion.baseTokenUnits + conversion.bonusTokenUnits;
        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).moveFungibleAsset(address(lockupContract), totalUnits);

        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).updateContractorProceeds(conversion.contractorProceedsETHWei);
        conversion.state = ConversionState.EXECUTED;
        conversions[_conversionId] = conversion;
        converterToLockupContracts[conversion.converter].push(lockupContract);
    }

    /// @notice Function to convert converter state to it's bytes representation (Maybe we don't even need it)
    /// @param state is conversion state
    /// @return bytes32 (hex) representation of state
    function convertConverterStateToBytes(ConverterState state) public pure returns (bytes32) {
        if(ConverterState.PENDING_APPROVAL == state) {
            return bytes32("PENDING_APPROVAL");
        }
        if(ConverterState.APPROVED == state) {
            return bytes32("APPROVED");
        }
        if(ConverterState.REJECTED == state) {
            return bytes32("REJECTED");
        }
    }


    /// @notice Function to check whether converter is approved or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterApproved(address _converter) public onlyContractorOrModerator view  returns (bool) {
        if(converterToState[_converter] == ConverterState.APPROVED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is rejected or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterRejected(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToState[_converter] == ConverterState.REJECTED) {
            return true;
        }
        return false;
    }


    /// @notice Function to check whether converter is cancelled or not
    /// @dev only contractor or moderator are eligible to call this function
    /// @param _converter is the address of converter
    /// @return true if yes, otherwise false
    function isConverterPendingApproval(address _converter) public view onlyContractorOrModerator returns (bool) {
        if(converterToState[_converter] == ConverterState.PENDING_APPROVAL) {
            return true;
        }
        return false;
    }


        function getConversion(
            uint conversionId
        ) external view returns (
            address,
            uint256,
            address,
            ConversionState,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
                string memory empty = "";
                if(conversion.isAnonymous == false) {
                    empty = conversion.contractor;
                }
                Conversion memory conversion = conversions[conversionId];
                return(
                    empty,
                    conversion.contractorProceedsETHWei,
                    conversion.converter,
                    conversion.state,
                    conversion.conversionAmount,
                    conversion.maxReferralRewardETHWei,
                    conversion.moderatorFeeETHWei,
                    conversion.baseTokenUnits,
                    conversion.bonusTokenUnits,
                    conversion.conversionCreatedAt,
                    conversion.conversionExpiresAt
                );
        }

    /// @notice Function to get all pending converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of pending converter addresses
    function getAllPendingConverters() public view onlyContractorOrModerator returns (address[]) {
        return (stateToConverter[bytes32("PENDING_APPROVAL")]);
    }

    /// @notice Function to get all rejected converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of rejected converter addresses
    function getAllRejectedConverters() public view onlyContractorOrModerator returns(address[]) {
        return stateToConverter[bytes32("REJECTED")];
    }


    /// @notice Function to get all approved converters
    /// @dev view function - no gas cost & only Contractor or Moderator can call this function - otherwise will revert
    /// @return array of approved converter addresses
    function getAllApprovedConverters() public view onlyContractorOrModerator returns(address[]) {
        return stateToConverter[bytes32("APPROVED")];
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
        ConverterState state = converterToState[_converter];
        bytes32 key = convertConverterStateToBytes(state);
        address[] memory pending = stateToConverter[key];
        for(uint i=0; i< pending.length; i++) {
            if(pending[i] == _converter) {
                stateToConverter[destinationState].push(_converter);
                pending[i] = pending[pending.length-1];
                delete pending[pending.length-1];
                stateToConverter[key] = pending;
                stateToConverter[key].length--;
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
        converterToState[_converter] = ConverterState.APPROVED;
    }

    /// @notice Function where we're going to move state of conversion from pending to rejected
    /// @dev private function, will be executed in another one
    /// @param _converter is the address of converter
    function moveFromPendingToRejectedState(address _converter) private {
        bytes32 destination = bytes32("REJECTED");
        moveFromStateAToStateB(_converter, destination);
        converterToState[_converter] = ConverterState.REJECTED;
    }


    /// @notice Function where we are approving converter
    /// @dev only moderator or contractor can call this method
    /// @param _converter is the address of converter
    function approveConverter(address _converter) public onlyContractorOrModerator {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL || converterToState[_converter] == ConverterState.REJECTED);
        moveFromPendingOrRejectedToApprovedState(_converter);
    }


    /// @notice Function where we can reject converter
    /// @dev only moderator or contractor can call this function
    /// @param _converter is the address of converter
    function rejectConverter(address _converter) public onlyContractorOrModerator  {
        require(converterToState[_converter] == ConverterState.PENDING_APPROVAL);
        moveFromPendingToRejectedState(_converter);
    }

    //
    //    /// @notice Function where contractor or moderator can cancel the converter
    //    function cancelConverter() public {
    //        require(converterToState[msg.sender] == ConversionState.REJECTED ||
    //        converterToState[msg.sender] == ConversionState.PENDING);
    //        moveFromPendingOrRejectedToCancelledState(msg.sender);
    //
    //        Conversion memory conversion = conversions[msg.sender];
    //        ITwoKeyAcquisitionCampaignERC20(twoKeyAcquisitionCampaignERC20).sendBackEthWhenConversionCancelled(msg.sender, conversion.conversionAmount);
    //    }
    //
    //
    //    function cancelAndRejectContract() external onlyTwoKeyAcquisitionCampaign {
    //        for(uint i=0; i<allLockUpContracts.length; i++) {
    //            TwoKeyLockupContract(allLockUpContracts[i]).cancelCampaignAndGetBackTokens(assetContractERC20);
    //        }
    //    }

}