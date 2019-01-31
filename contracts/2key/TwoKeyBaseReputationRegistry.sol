pragma solidity ^0.4.24;

import "./Upgradeable.sol";
import "../interfaces/ITwoKeyReg.sol";
/**
 * @author Nikola Madjarevic
 * Created at 1/31/19
 */
contract TwoKeyBaseReputationRegistry is Upgradeable{
    address twoKeyRegistry;

    constructor() {

    }

    function setInitialParams(address _twoKeyRegistry) {
        require(twoKeyRegistry == address(0));
        twoKeyRegistry = _twoKeyRegistry;
    }

    mapping(address => int) address2contractorGlobalReputationScoreWei;
    mapping(address => int) address2converterGlobalReputationScoreWei;
    mapping(address => int) address2referrerGlobalReputationScoreWei;

    function updateOnConversionCreatedEvent(address converter, address contractor, address [] referrers) public {
        uint d = 0;
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + 5;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + 5;
    }

    function updateOnConversionExecutedEvent(address converter, address contractor, address [] referrers) public {
        uint d = 0;
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] + 10;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + 10;
    }

    function updateOnConversionRejectedEvent(address converter, address contractor, address [] referrers) public {
        uint d = 0;
        address2contractorGlobalReputationScoreWei[contractor] = address2contractorGlobalReputationScoreWei[contractor] - 5;
        address2converterGlobalReputationScoreWei[converter] = address2converterGlobalReputationScoreWei[converter] + 3;
    }


}
