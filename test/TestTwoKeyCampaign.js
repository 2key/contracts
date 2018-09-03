const { increaseTime, latestTime, duration } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');
const BigNumber = web3.BigNumber;

const HOUR = 3600;

/// contracts
const TwoKeyWhitelisted = artifacts.require("TwoKeyWhitelisted");
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyAcquisitionCampaignERC20 = artifacts.require("TwoKeyAcquisitionCampaignERC20");
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");
const TwoKeyCampaignARC = artifacts.require("TwoKeyCampaignARC");
const TwoKeyCampaignInventory = artifacts.require("TwoKeyCampaignInventory.sol");


/// tokens
const StandardToken = artifacts.require("StandardToken");
const ERC20Mock = artifacts.require("ERC20TokenMock");

contract('TwoKeyCampaign', async (accounts) => {

    let whitelistInfluencer, 
        whitelistConverter, 
        eventSource, 
        twoKeyEconomy,
        twoKeyAcquisitionCampaignERC20,
        twoKeyAdmin,
        upgradeableExchange,
        erc20;


    const coinbase = accounts[0];
    const contractor = accounts[2];
    const moderator = accounts[1];
    const campaignCreator = accounts[3];
    const escrowPrecentage = 10;
    const rate = 2;
    const maxPi = 15;
    const assetName = "TestingTokenERC20";


    const electorateAdmins = accounts[4];
    const walletExchange = accounts[5];

    before(async () => {
        // Contractor input addresses
        erc20 = await ERC20Mock.new({
            from: coinbase
        });

        const openingTime = latestTime() + duration.minutes(5);
        const closingTime = latestTime() + duration.minutes(30);

        /*
            Singleton area (one per TwoKeyNetwork)
         */
        upgradeableExchange = await TwoKeyUpgradableExchange.new(100, walletExchange, erc20.address);
        twoKeyAdmin = await TwoKeyAdmin.new(electorateAdmins, upgradeableExchange.address);
        twoKeyEconomy = await TwoKeyEconomy.new(twoKeyAdmin.address);
        eventSource = await TwoKeyEventSource.new(twoKeyAdmin.address);

        /*
            Subcontracts required for TwoKeyCampaign
         */

        /// TODO: Move subcontracts to be deployed in TwoKeyCampaign constructor

        whitelistInfluencer = await TwoKeyWhitelisted.new();
        whitelistConverter = await TwoKeyWhitelisted.new();

        twoKeyAcquisitionCampaignERC20 = await TwoKeyAcquisitionCampaignERC20.new(
            eventSource.address,
            twoKeyEconomy.address,
            whitelistInfluencer.address,
            whitelistConverter.address,

            contractor, //Address of the user
            moderator, //Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts

            openingTime,
            closingTime,
            closingTime,
            escrowPrecentage,
            rate,
            maxPi,
            {
                from: campaignCreator,
                gas: '8000000'
            }
        );
    });
    it("Should print addresses of contracts", async() => {
        console.log("[ERC20] : " + erc20.address);
        console.log("[TwoKeyUpgradebleExchange] : " + upgradeableExchange.address);
        console.log("[TwoKeyAdmin] : " + twoKeyAdmin.address);
        console.log("[TwoKeyEventSource] : " + eventSource.address);
        console.log("[TwoKeyWhitelistConverter] : " + whitelistConverter.address);
        console.log("[TwoKeyWhiteListInfluencer] : " + whitelistInfluencer.address);
        console.log("[TwoKeyAcquisitionCampaignERC20] : " + twoKeyAcquisitionCampaignERC20.address);
    });


    it("transfer fungible to campaign", async () => {
        await erc20.transfer(contractor, 200, {
            from: coinbase
        });

        await erc20.approve(campaign.address, 20, {
            from: contractor,
        });

        // await campaign.addFungibleChild(tokenIDFT, erc20, 20, {
        //     from: campaignCreator
        // });
        // await campaign.setPriceFungible(tokenIDFT, erc20, ether(5), {
        //     from: campaignCreator
        // });
    });
  
   
});
