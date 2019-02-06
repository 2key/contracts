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

    using SafeMath for uint;
    address twoKeyRegistry;
    uint public x = 0;
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

    mapping(address => ReputationScore) public address2contractorGlobalReputationScoreWei;
    mapping(address => ReputationScore) public address2converterGlobalReputationScoreWei;
    mapping(address => ReputationScore) public plasmaAddress2referrerGlobalReputationScoreWei;

    struct ReputationScore {
        uint points;
        bool isPositive;
    }

    /**
     * @notice If the conversion created event occured, 5 points for the converter and contractor + 5/distance to referrer
     * @dev This function can only be called by TwoKeyConversionHandler contract assigned to the Acquisition from method param
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param acquisitionCampaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionCreatedEvent(address converter, address contractor, address acquisitionCampaign) public {
        validateCall(acquisitionCampaign);
        uint d = 1;
        uint initialRewardWei = 5*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);

        address2contractorGlobalReputationScoreWei[contractor] = addToReputationScore(initialRewardWei, address2contractorGlobalReputationScoreWei[contractor]);
        address2converterGlobalReputationScoreWei[converter] = addToReputationScore(initialRewardWei, address2converterGlobalReputationScoreWei[converter]);

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] = addToReputationScore(initialRewardWei/d,plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]]);
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
        uint d = 1;
        uint initialRewardWei = 10*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);

        address2contractorGlobalReputationScoreWei[contractor] = addToReputationScore(initialRewardWei, address2contractorGlobalReputationScoreWei[contractor]);
        address2converterGlobalReputationScoreWei[converter] = addToReputationScore(initialRewardWei, address2converterGlobalReputationScoreWei[converter]);

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] = addToReputationScore(initialRewardWei/d,plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]]);
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
        uint d = 1;
        uint initialRewardWei = 10*(10**18);

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);

        address2contractorGlobalReputationScoreWei[contractor] = subFromReputationScore(initialRewardWei, address2contractorGlobalReputationScoreWei[contractor]);
        address2converterGlobalReputationScoreWei[converter] = subFromReputationScore(initialRewardWei, address2converterGlobalReputationScoreWei[converter]);

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] = subFromReputationScore(initialRewardWei/d,plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]]);
            d = d + 1;
        }
    }

    /**
     * @notice Function to handle additions to reputation scores
     * @param value is value we want to add
     * @param score is the reputation score we want to modify
     */
    function addToReputationScore(uint value, ReputationScore memory score) internal view returns (ReputationScore) {
        if(score.points == 0) {
            score.points = value;
            score.isPositive = true;
        }
        if(score.isPositive) {
            score.points = score.points.add(value);
        } else {
            if(score.points > value) {
                score.points = score.points.sub(value);
            } else {
                score.points = value.sub(score.points);
                score.isPositive = true;
            }
        }
        return score;
    }

    /**
     * @notice Function to handle substract operations on reputation scores
     * @param value is the value we want to substract
     * @param score is the score we want to modify
     */
    function subFromReputationScore(uint value, ReputationScore memory score) internal view returns (ReputationScore) {
        if(score.points == 0) {
            score.points = value;
            score.isPositive = false;
        } else if(score.isPositive) {
            if(score.points > value) {
                score.points = score.points.sub(value);
            } else {
                score.points = value.sub(score.points);
                score.isPositive = false;
            }
        } else {
            score.points = score.points.add(value);
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

    function getReferrers(address converter, address acquisitionCampaign) public view returns (address[]) {
        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        return ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);
    }

//    /**
//     * @notice Function where user can check his reputation points
//     * TODO: See how to handle integer overflows
//     */
//    function getMyRewards() public returns (int,int,int) {
//        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(msg.sender);
//        return(
//            address2contractorGlobalReputationScoreWei[msg.sender],
//            address2converterGlobalReputationScoreWei[msg.sender],
//            plasmaAddress2referrerGlobalReputationScoreWei[plasma]
//        );
//    }



}
