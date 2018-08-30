pragma solidity ^0.4.24;

import "./TwoKeyCampaignInventory.sol";
import "./TwoKeyWhitelisted.sol";
import "./TwoKeyCampaign.sol";
import "./TwoKeyCampaign.sol";
import "./TwoKeyEventSource.sol";
import "./TwoKeyEconomy.sol";


contract TwoKeyCampaignFactory {

    TwoKeyWhitelisted whitelistInfluencer;
    TwoKeyWhitelisted whitelistConverter;
    TwoKeyCampaignInventory twoKeyCampaignInventory;

    constructor () public {
        whitelistInfluencer = new TwoKeyWhitelisted();
        whitelistConverter = new TwoKeyWhitelisted();
        twoKeyCampaignInventory = new TwoKeyCampaignInventory();
    }


    function getAddresses() public view returns (address, address, address) {
        return (address(whitelistInfluencer), address(whitelistConverter), address(twoKeyCampaignInventory));
    }


}
