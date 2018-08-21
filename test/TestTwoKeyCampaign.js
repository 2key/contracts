const { increaseTime, latestTime, duration } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');
const BigNumber = web3.BigNumber;

const HOUR = 3600;

/// contracts
const TwoKeyWhitelisted = artifacts.require("TwoKeyWhitelisted");
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyCampaign = artifacts.require("TwoKeyCampaign");
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");
const TwoKeyARC = artifacts.require("TwoKeyARC");
const ComposableAssetFactory = artifacts.require("ComposableAssetFactory");


/// tokens
const StandardToken = artifacts.require("StandardToken");
const ERC721Mock = artifacts.require("ERC721TokenMock");
const ERC20Mock = artifacts.require("ERC20TokenMock");

contract('TwoKeyCampaign', async (accounts) => {

    let whitelistInfluencer, 
        whitelistConverter, 
        eventSource, 
        economy,
        campaign,
        twoKeyAdmin,
        upgradeableExchange,
        twoKeyARC,
        composableAssetFactory,
        erc721,
        standardToken,
        erc20;


    const coinbase = accounts[0];
    const tokenIndex = "123";
    const contractor = accounts[2];
    const moderator = accounts[1];
    const campaignCreator = accounts[3];
    const tokenIDNFT = "1";
    const tokenIDFT = "2";
    const escrowPrecentage = 10;
    const rate = 2;
    const maxPi = 15;


    const electorateAdmins = accounts[4];
    const walletExchange = accounts[5];
    before(async () => {
        // Deploy instance of erc20
        erc20 = await ERC20Mock.new({
            from: coinbase
        });

        upgradeableExchange = await TwoKeyUpgradableExchange.new(100, walletExchange, erc20.address);
        economy = await TwoKeyEconomy.new();
        twoKeyAdmin = await TwoKeyAdmin.new(economy.address, electorateAdmins, upgradeableExchange.address);

        eventSource = await TwoKeyEventSource.new(twoKeyAdmin.address);
        whitelistInfluencer = await TwoKeyWhitelisted.new();
        whitelistConverter = await TwoKeyWhitelisted.new();
        twoKeyARC = await TwoKeyARC.new(eventSource.address, contractor);

        erc721 = await ERC721Mock.new("NFT", "NFT");
        standardToken = await StandardToken.new();

        await erc721.mint(contractor, tokenIndex, {
            from: coinbase,
        });


        const openingTime = latestTime() + duration.minutes(1);
        const closingTime = latestTime() + duration.minutes(30);
        const durationCampaign = duration.minutes(30);
        const durationEscrow = duration.minutes(5);

        composableAssetFactory = await ComposableAssetFactory.new(openingTime, closingTime);

        // campaign = await TwoKeyCampaign.new(
        //     eventSource.address,
        //     economy.address,
        //     whitelistInfluencer.address,
        //     whitelistConverter.address,
        //
        //     contractor,
        //     moderator,
        //
        //     openingTime,
        //     closingTime,
        //     closingTime,
        //     escrowPrecentage,
        //     rate,
        //     maxPi
        //     ,
        //     {
        //         from: accounts[0]
        //     }
        // );
    });
    it("Should print addresses of contracts", async() => {
        console.log("[ERC20] : " + erc20.address);
        console.log("[ERC721] : " + erc721.address);
        console.log("[StandardToken] : " + standardToken.address);
        console.log("[TwoKeyUpgradebleExchange] : " + upgradeableExchange.address);
        console.log("[TwoKeyAdmin] : " + twoKeyAdmin.address);
        console.log("[TwoKeyEventSource] : " + eventSource.address);
        // console.log("TwoKeyCampaign : " + campaign.address);
        console.log("[TwoKeyWhitelistConverter] : " + whitelistConverter.address);
        console.log("[TwoKeyWhiteListInfluencer] : " + whitelistInfluencer.address);
        console.log("[TwoKeyARC] : " + twoKeyARC.address);
        console.log("[ComposableAssetFactory] : " + composableAssetFactory.address);
    });
    // it("transfer fungible to compaign", async () => {
    //
    //
    //     await erc20.transfer(contractor, 200, {
    //         from: coinbase
    //     });

        // await erc20.approve(campaign.address, 20, {
        //     from: contractor,
        // });

    //     await campaign.addFungibleChild(tokenIDFT, erc20, 20, {
    //         from: campaignCreator
    //     });
    //     await campaign.setPriceFungible(tokenIDFT, erc20, ether(5), {
    //         from: campaignCreator
    //     });
    // });
  
   
});
