pragma solidity ^0.4.24;
import "../2key/TwoKeyWhitelisted.sol";

contract TwoKeyAcquisitionCampaignERC20Predeply {
    TwoKeyWhitelisted whitelistInfluencer;
    TwoKeyWhitelisted whitelistConverter;

    constructor() {
        whitelistInfluencer = new TwoKeyWhitelisted();
        whitelistConverter = new TwoKeyWhitelisted();
    }

    function getAddresses() public view returns (address, address) {
        return (whitelistInfluencer, whitelistConverter);
    }

}
