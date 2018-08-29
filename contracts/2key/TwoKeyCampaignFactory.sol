pragma solidity ^0.4.24;

import "./ComposableAssetFactory.sol";
import "./TwoKeyWhitelisted.sol";
import "./TwoKeyCampaign.sol";
import "./TwoKeyCampaign.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyEconomy.sol";


contract TwoKeyCampaignFactory {

    TwoKeyCampaign twoKeyCampaign;
    TwoKeyWhitelisted whitelistInfluencer;
    TwoKeyWhitelisted whitelistConverter;
    ComposableAssetFactory composableAssetFactory;

    constructor (uint openingTime, uint closingTime) public {
        whitelistInfluencer = new TwoKeyWhitelisted();
        whitelistConverter = new TwoKeyWhitelisted();
        composableAssetFactory = new ComposableAssetFactory(openingTime, closingTime);
    }

//                TwoKeyEventSource twoKeyEventSource, TwoKeyEconomy twoKeyEconomy,
//                address _contractor,
//                // set moderator as admin of twokeywhitelist contracts here
//                address _moderator,
//                uint256 _expiryConversion,
//                uint256 _escrowPercentage,
//                uint256 _rate,
//                uint256 _maxPi, uint openingTime, uint closingTime) {
//
//
//
//        twoKeyCampaign = new TwoKeyCampaign(
//                twoKeyEventSource,
//                twoKeyEconomy,
//                whitelistInfluencer,
//                whitelistConverter,
//                composableAssetFactory,
//                _contractor,
//                _moderator,
//                _expiryConversion,
//                _escrowPercentage,
//                _rate,
//                _maxPi);
//    }

//    function addTwoKeyCampaignContract(TwoKeyEventSource twoKeyEventSource, TwoKeyEconomy twoKeyEconomy,
//        TwoKeyWhitelisted _whitelistInfluencer, TwoKeyWhitelisted _whitelistConverter,
//        ComposableAssetFactory _composableAssetFactory,
//        address _contractor,
//    // set moderator as admin of twokeywhitelist contracts here
//        address _moderator,
//        uint256 _expiryConversion,
//        uint256 _escrowPercentage,
//        uint256 _rate,
//        uint256 _maxPi) public {
//        whitelistInfluencer = new TwoKeyWhitelisted();
//        whitelistConverter = new TwoKeyWhitelisted();
//        composableAssetFactory = new ComposableAssetFactory(openingTime, closingTime);
////        twoKeyCampaign = new TwoKeyCampaign(
////            twoKeyEventSource,
////            twoKeyEconomy,
////            _whitelistInfluencer,
////            _whitelistConverter,
////            _composableAssetFactory,
////            _contractor,
////            _moderator,o
////            _expiryConversion,
////            _escrowPercentage,
////            _rate,
////            _maxPi);
//    }

    function getAddresses() public view returns (address, address, address) {
        return (address(whitelistInfluencer), address(whitelistConverter), address(composableAssetFactory));
    }


}
