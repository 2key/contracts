const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const TwoKeyCampaignInventory = artifacts.require('TwoKeyCampaignInventory');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const Call = artifacts.require('Call');

/*
    address _twoKeyEventSource, address _twoKeyEconomy,
    address _converterWhitelist, address _referrerWhitelist,
    address _moderator, address _assetContractERC20, uint _campaignStartTime, uint _campaignEndTime,
    uint _expiryConversion, uint _moderatorFeePercentage, uint _maxReferralRewardPercent, uint _maxConverterBonusPercent,
    uint _pricePerUnitInETH, uint _minContributionETH, uint _maxContributionETH,
    uint _conversionQuota
 */


module.exports = function deploy(deployer) {
    if (deployer.network.startsWith('dev') || deployer.network === 'ropsten' || (deployer.network.startsWith('rinkeby-test') && !process.env.DEPLOY)) {
        deployer.deploy(TwoKeyConversionHandler,1012019,180,6,180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call,TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20, EventSource.address, TwoKeyEconomy.address, TwoKeyConversionHandler.address,
                '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address,
                12345,15345,12345,5,5,5,5,12,15,1))
            .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
            .then(() => true);
    }
};
