const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const TwoKeyCampaignInventory = artifacts.require('TwoKeyCampaignInventory');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const Call = artifacts.require('Call');
const TwoKeyHackEventSource = artifacts.require('TwoKeyHackEventSource');

/*
    address _twoKeyEventSource, address _twoKeyEconomy,
    address _converterWhitelist, address _referrerWhitelist,
    address _moderator, address _assetContractERC20, uint _campaignStartTime, uint _campaignEndTime,
    uint _expiryConversion, uint _moderatorFeePercentage, uint _maxReferralRewardPercent, uint _maxConverterBonusPercent,
    uint _pricePerUnitInETH, uint _minContributionETH, uint _maxContributionETH,
    uint _conversionQuota
 */


module.exports = function deploy(deployer) {
    let x = 1;
    if (deployer.network.startsWith('dev') || deployer.network === 'ropsten' || (deployer.network.startsWith('rinkeby-test') && !process.env.DEPLOY)) {
        deployer.deploy(TwoKeyConversionHandler, 1012019, 180, 6, 180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyHackEventSource))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20, TwoKeyHackEventSource.address, TwoKeyConversionHandler.address,
                '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address,
                [12345, 15345, 12345, 5, 5, 5, 5, 12, 15, 1], 'USD'))
            .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
            .then(() => true)
            .then(() => EventSource.deployed().then(async (eventSource) => {
                console.log("... Adding TwoKeyAcquisitionCampaign to EventSource");
                await new Promise(async (resolve, reject) => {
                    try {
                        let txHash = await eventSource.addContract(TwoKeyAcquisitionCampaignERC20.address, {gas: 7000000}).then(() => true);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
                console.log("Added TwoKeyAcquisition: " + TwoKeyAcquisitionCampaignERC20.address + "  to EventSource : " + EventSource.address + "!");
            })).then(() => true);
    }
}
