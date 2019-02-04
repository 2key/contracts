pragma solidity ^0.4.24;

import "./Upgradeable.sol";

import '../openzeppelin-solidity/contracts/math/SafeMath.sol';

import "../interfaces/ITwoKeyReg.sol";
import "../interfaces/ITwoKeyAcquisitionLogicHandler.sol";
import "../interfaces/ITwoKeyAcquisitionCampaignGetLogicHandler.sol";

/**
 * @author Nikola Madjarevic
 * Created at 1/31/19
 */
contract TwoKeyBaseReputationRegistry is Upgradeable {
    address twoKeyRegistry;

    constructor() {

    }

    function setInitialParams(address _twoKeyRegistry) {
        require(twoKeyRegistry == address(0));
        twoKeyRegistry = _twoKeyRegistry;
    }

    mapping(address => int) address2contractorGlobalReputationScoreWei;
    mapping(address => int) address2converterGlobalReputationScoreWei;
    mapping(address => int) plasmaAddress2referrerGlobalReputationScoreWei;

    function updateOnConversionCreatedEvent(address converter, address contractor, address acquisitionCampaign) public {
        int d = 1;
        int initialRewardWei = 5000000000000000000;

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + initialRewardWei;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + initialRewardWei;

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] += initialRewardWei/d;
            d = d + 1;
        }
    }

    function updateOnConversionExecutedEvent(address converter, address contractor, address acquisitionCampaign) public {
        int d = 1;
        int initialRewardWei = 10000000000000000000;

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + initialRewardWei;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + initialRewardWei;

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] += initialRewardWei/d;
            d = d + 1;
        }

    }

    function updateOnConversionRejectedEvent(address converter, address contractor, address acquisitionCampaign) public {
        int d = 1;
        int initialPenaltyWei = 10000000000000000000;

        address logicHandlerAddress = getLogicHandlerAddress(acquisitionCampaign);
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] - 5000000000000000000;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] - 3000000000000000000;

        address[] memory referrers = ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter, acquisitionCampaign);

        for(uint i=0; i<referrers.length; i++) {
            plasmaAddress2referrerGlobalReputationScoreWei[referrers[i]] -= initialPenaltyWei/d;
            d = d + 1;
        }
    }


    function getLogicHandlerAddress(address acquisitionCampaign) internal view returns (address) {
        return ITwoKeyAcquisitionCampaignGetLogicHandler(acquisitionCampaign).twoKeyAcquisitionLogicHandler();
    }




}
