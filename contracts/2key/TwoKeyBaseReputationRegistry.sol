pragma solidity ^0.4.24;

import "./Upgradeable.sol";

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignGetStaticAddresses.sol";
import "./MaintainingPattern.sol";

/**
 * @author Nikola Madjarevic
 * Created at 1/31/19
 */
contract TwoKeyBaseReputationRegistry is Upgradeable, MaintainingPattern {

    address twoKeyRegistry;

    constructor() {

    }

    /**
     * @notice Since using singletone pattern, this is replacement for the constructor
     * @param _twoKeyRegistry is the address of twoKeyRegistry contract
     */
    function setInitialParams(address _twoKeyRegistry, address _twoKeyAdmin, address[] _maintainers) {
        require(twoKeyRegistry == address(0));
        require(twoKeyAdmin == address(0));
        twoKeyAdmin = _twoKeyAdmin;
        twoKeyRegistry = _twoKeyRegistry;
        isMaintainer[msg.sender] = true; //also the deployer will be authorized maintainer
        for(uint i=0; i<_maintainers.length; i++) {
            isMaintainer[_maintainers[i]] = true;
        }
    }

    mapping(address => int) address2contractorGlobalReputationScoreWei;
    mapping(address => int) address2converterGlobalReputationScoreWei;
    mapping(address => int) plasmaAddress2referrerGlobalReputationScoreWei;

    /**
     * @notice If the conversion created event occured, 5 points for the converter and contractor + 5/distance to referrer
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionCreatedEvent(address converter, address contractor, address acquisitionCampaign) public {
        validateCall(acquisitionCampaign);
        int d = 1;
        int initialRewardWei = 5*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + initialRewardWei;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + initialRewardWei;

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] += initialRewardWei/d;
            d = d + 1;
        }
    }

    /**
     * @notice If the conversion executed event occured, 10 points for the converter and contractor + 10/distance to referrer
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionExecutedEvent(address converter, address contractor, address acquisitionCampaign) public {
        validateCall(acquisitionCampaign);
        int d = 1;
        int initialRewardWei = 10*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + initialRewardWei;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + initialRewardWei;

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] += initialRewardWei/d;
            d = d + 1;
        }
    }

    /**
     * @notice If the conversion rejected event occured, giving penalty points
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionRejectedEvent(address converter, address contractor, address acquisitionCampaign) public {
        validateCall(acquisitionCampaign);
        int d = 1;
        int initialPenaltyWei = 10*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] - 5*(10**18);
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] - 3*(10**18);

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] -= initialPenaltyWei/d;
            d = d + 1;
        }
    }


    /**
     * @notice Internal getter from Acquisition campaign to fetch logic handler address
     */
    function getLogicHandlerAddress(address acquisitionCampaign) internal view returns (address) {
        return ITwoKeyAcquisitionCampaignGetStaticAddresses(acquisitionCampaign).twoKeyAcquisitionLogicHandler();
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch conersion handler address
     */
    function getConversionHandlerAddress(address acquisitionCampaign) internal view returns (address) {
        return ITwoKeyAcquisitionCampaignGetStaticAddresses(acquisitionCampaign).conversionHandler();
    }

    /**
     * @notice Function to validate call to method
     */
    function validateCall(address acquisitionCampaign) internal {
        address conversionHandler = getConversionHandlerAddress(acquisitionCampaign);
        require(msg.sender == conversionHandler);
    }

    /**
     * @notice Function where user can check his reputation points
     * TODO: See how to handle integer overflows
     */
    function getMyRewards() public returns (int,int,int) {
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(msg.sender);
        return(
            address2contractorGlobalReputationScoreWei[msg.sender],
            address2converterGlobalReputationScoreWei[msg.sender],
            plasmaAddress2referrerGlobalReputationScoreWei[plasma]
        );
    }



}
