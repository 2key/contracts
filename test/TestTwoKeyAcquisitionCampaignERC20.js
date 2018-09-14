const { increaseTime, latestTime, duration, free_take, free_join, privateToPublic, validate_join, generatePrivateKey } = require("./utils");
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

contract('TwoKeyAcquisitionCampaignERC20', async (accounts) => {

// ===============================================================================================
// Variables we're going to use in tests, predefined

    let whitelistInfluencer, 
        whitelistConverter, 
        twoKeyEventSource,
        twoKeyEconomy,
        twoKeyAcquisitionCampaignERC20,
        twoKeyAdmin,
        upgradeableExchange,
        erc20;


    const coinbase = accounts[0];
    const moderator = accounts[1];
    const campaignCreator = accounts[3];
    const campaignReferrer = accounts[4];
    const campaignConverter = accounts[6];
    const accountForAndri = accounts[5];
    const userAddress = accounts[7];
    const escrowPrecentage = 10;
    const rate = 2;
    const maxPi = 15;
    const assetName = "TestingTokenERC20";
    const quota = 5;

    const electorateAdmins = accounts[4];
    const walletExchange = accounts[5];

// ===============================================================================================




// ===============================================================================================
// Initial setup of contracts which are going to be used in tests

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
        twoKeyAdmin = await TwoKeyAdmin.new(electorateAdmins);
        upgradeableExchange = await TwoKeyUpgradableExchange.new(100, walletExchange, erc20.address, twoKeyAdmin.address);

        twoKeyEconomy = await TwoKeyEconomy.new(twoKeyAdmin.address);
        twoKeyEventSource = await TwoKeyEventSource.new(twoKeyAdmin.address);

        /*
            Subcontracts required for TwoKeyCampaign
         */

        whitelistInfluencer = await TwoKeyWhitelisted.new();
        whitelistConverter = await TwoKeyWhitelisted.new();

        twoKeyAcquisitionCampaignERC20 = await TwoKeyAcquisitionCampaignERC20.new(
            twoKeyEventSource.address,
            twoKeyEconomy.address,
            whitelistInfluencer.address,
            whitelistConverter.address,

            moderator, //Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts

            openingTime,
            closingTime,
            closingTime,
            escrowPrecentage,
            rate,
            maxPi,
            twoKeyEconomy.address,
            quota,
            {
                from: campaignCreator,
                gas: '8000000'
            }
        );

    });

// Ended setup of contracts
// ===============================================================================================



    it("should print addresses of contracts", async() => {
        console.log("================================DEPLOYED CONTRACT ADDRESSES====================================");
        console.log("[ERC20] : " + erc20.address);
        console.log("[TwoKeyUpgradebleExchange] : " + upgradeableExchange.address);
        console.log("[TwoKeyAdmin] : " + twoKeyAdmin.address);
        console.log("[TwoKeyEventSource] : " + twoKeyEventSource.address);
        console.log("[TwoKeyWhitelistConverter] : " + whitelistConverter.address);
        console.log("[TwoKeyWhiteListInfluencer] : " + whitelistInfluencer.address);
        console.log("[TwoKeyAcquisitionCampaignERC20] : " + twoKeyAcquisitionCampaignERC20.address);
        console.log("===============================================================================================");
    });

    // it("should add asset contract to the campaign", async() => {
    //    await twoKeyAcquisitionCampaignERC20.addAssetContractERC20(erc20.address);
    //
    //    let assetContract = await twoKeyAcquisitionCampaignERC20.getAssetContractAddress();
    //
    //    assert.equal(erc20.address, assetContract, "asset contract is not added successfully");
    //    console.log("Asset contract added to campaign");
    //
    // });

    it("should accept ether sent to contract", async() => {
        let txHash = await twoKeyAcquisitionCampaignERC20.sendTransaction({from: coinbase, value: 1000});
        assert.equal(txHash.logs[0].event, "ReceivedEther", "event ReceivedEther should be emitted");

        let balance = await twoKeyAcquisitionCampaignERC20.checkAmountAddressSent(coinbase);
        assert.equal(balance,1000, "values not updated well");
    });


    it("should have not any ERC20 on contract", async() => {
        let balance = await twoKeyAcquisitionCampaignERC20.getContractBalance();
        assert.equal(balance, 0, "balance is not well updated");
    });

    it("should have 1B balance on TwoKeyAdmin", async() => {
       let balance = await twoKeyEconomy.balanceOf(twoKeyAdmin.address);
       assert.equal(balance.c[0], 1000000000, "should be 1 mil");
       console.log(balance);
    });

    it("should transfer some amount to an address", async() => {

        let balanceBefore = await twoKeyEconomy.balanceOf(accountForAndri);
        console.log("Andrii balance before transfer: " + balanceBefore);
        await twoKeyAdmin.transfer2KeyTokens(twoKeyEconomy.address, accountForAndri, 5000);
        let balanceOfAndri = await twoKeyEconomy.balanceOf(accountForAndri);
        console.log("Andrii balance after transfer: " + balanceOfAndri);

        let balanceOfAdmin = await twoKeyEconomy.balanceOf(twoKeyAdmin.address);
        console.log(balanceOfAdmin);
    });

    it("should transfer", async() => {
        try {
            await twoKeyEconomy.transfer(accounts[1], 1000, {from: accountForAndri});
        } catch(error) {
            console.log(error);
        }

        let balanceOfAndri = await twoKeyEconomy.balanceOf(accountForAndri);
        assert.equal(balanceOfAndri, 4000, "should be the same");
    });


    it("should transfer funds to contract" ,async() => {
        await twoKeyAdmin.transfer2KeyTokens(twoKeyEconomy.address, twoKeyAcquisitionCampaignERC20.address, 1000);
        await twoKeyAcquisitionCampaignERC20.checkAndUpdateInventoryBalance();
        let balance  = await twoKeyAcquisitionCampaignERC20.checkInventoryBalance();
        
        console.log(balance);
    });

    // it("should fullFill with TwoKey", async() => {
    //     await twoKeyAdmin.transfer2KeyTokens(twoKeyEconomy.address, accounts[5], 5000);
    //
    // });
    // it("should get public link key", async() => {
    //     await twoKeyAcquisitionCampaignERC20.setPublicLinkKey(userAddress, {from: campaignCreator});
    //     let key = await twoKeyAcquisitionCampaignERC20.public_link_key.call(campaignCreator);
    //     assert.equal(key, userAddress, "keys are not equal");
    // });

    it("should have initial balance of total supply", async() => {
        let balance = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignCreator);
        console.log("Initial balance of campaignCreator(contractor) is : " + balance);
    });




    it("should have 1 arc on this address" , async() => {
       let balance = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignReferrer);
       console.log("Balance after: " + balance);
    });

    let var1, var2;

    it("should be the same addresses ", async() => {
        let pk = generatePrivateKey();
        let public_address = privateToPublic(pk);
        const private_key = pk.toString('hex');


        let cutBefore = await twoKeyAcquisitionCampaignERC20.influencer2cut.call(campaignCreator);
        console.log("CUT BEFORE : " + cutBefore);
        await twoKeyAcquisitionCampaignERC20.setPubLinkWithCut(`0x${public_address}`, 10, {from: campaignCreator});
        let res = await twoKeyAcquisitionCampaignERC20.public_link_key.call(campaignCreator);
        let cut = await twoKeyAcquisitionCampaignERC20.influencer2cut.call(campaignCreator);

        console.log("CUT AFTER : " + cut);
        assert.equal(res, `0x${public_address}`, "they are not equal");

        var1 = private_key;
        var2 = "";
        console.log(res);
    });


    it("should join off chain", async() => {
        let pk = generatePrivateKey();
        let public_address = privateToPublic(pk);
        const private_key = pk.toString('hex');

        let link = free_join(campaignReferrer, public_address, campaignCreator, var1, var2, 3);
        console.log("Link generated: " + link);

        let msg = free_take(campaignConverter, campaignReferrer, private_key, link);

        console.log("Msg generated: " + msg);

        let balConv = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignConverter);
        let balRef = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignReferrer);
        let balCreator = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignCreator);

        console.log("Balance of creator before: " + balCreator);
        console.log("Balance of converter before: " + balConv);
        console.log("Balance of referrer before: " + balRef);

        let trnx = await twoKeyAcquisitionCampaignERC20.transferSig(msg, {from: campaignConverter});
        // console.log(trnx.logs);

        let balConvAfter = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignConverter);
        let balRefAfter = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignReferrer);
        let balCreatorAfter = await twoKeyAcquisitionCampaignERC20.balanceOf(campaignCreator);

        console.log("Balance of creator after: " + balCreatorAfter);
        console.log("Balance of converter after: " +balConvAfter);
        console.log("Balance of ref after: " + balRefAfter);

        console.log("CAMPAIGN CREATOR: "  + campaignCreator);
        console.log("CAMPAIGN REFERRER: " + campaignReferrer);
        console.log("CAMPAIGN CONVERTER : " + campaignConverter);


    });




    // it("should have fungible balance after transfered", async() => {
    //     await twoKeyAcquisitionCampaignERC20.addAssetContractERC20(erc20.address);
    //     let some_address = accounts[4];
    //     let some_address2 = accounts[5];
    //
    //
    //     // Transfer some amount of ERC20 to 2 random addresses
    //     await erc20.transfer(some_address, 200, {
    //         from: coinbase
    //     });
    //     await erc20.transfer(some_address2, 1000, {
    //         from:coinbase
    //     });
    //
    //     // Approve TwoKeyAcquisitionCampaign contract to get from that addresses tokens
    //     await erc20.approve(twoKeyAcquisitionCampaignERC20.address, 200, {
    //         from:some_address
    //     });
    //     await erc20.approve(twoKeyAcquisitionCampaignERC20.address, 1000, {
    //         from: some_address2
    //     });
    //
    //     // call the addFungibleAsset methods
    //     await twoKeyAcquisitionCampaignERC20.addFungibleAsset(200, {from: some_address});
    //
    //     // validate is balance well updated
    //     let balance = await twoKeyAcquisitionCampaignERC20.getContractBalance();
    //     assert.equal(balance, 200, "balance is not well updated");
    //
    //
    //     // call again addFungibleAsset methods to check if it works as expected
    //     await twoKeyAcquisitionCampaignERC20.addFungibleAsset(1000, {from: some_address2});
    //     balance = await twoKeyAcquisitionCampaignERC20.getContractBalance();
    //
    //     // final check for the balance
    //     assert.equal(balance, 1200, "balance is not well updated after 2 incoming transfers");
    // });
    //
    //
    // it("should transfer fungible assets to another address", async() => {
    //     await twoKeyAcquisitionCampaignERC20.transferFungibleAsset(accounts[6], 500);
    //     let balance = await twoKeyAcquisitionCampaignERC20.getContractBalance();
    //     assert.equal(balance, 700, "balance should be 700");
    // });
    //
    // it("should transfer some balance from TwoKeyEconomy to an address", async() => {
    //     await twoKeyEconomy.transfer(userAddress, 5000, {from : coinbase});
    //
    //     let balance = await twoKeyEconomy.balanceOf(userAddress);
    //     assert.equal(balance, 5000, "balance is not well updated");
    // });
    //
    // it("should buy with 2key tokens", async() => {
    //     await twoKeyEconomy.approve(twoKeyAcquisitionCampaignERC20.address, 2000, {from: userAddress});
    //     await twoKeyAcquisitionCampaignERC20.buyFromWithTwoKey(userAddress, assetName, erc20.address, 2000, {from: userAddress});
    //
    //     let balance = await twoKeyEconomy.balanceOf(twoKeyAcquisitionCampaignERC20.address);
    //     assert.equal(balance, 2000, "balance is not well updated");
    // });
    //
    // it("should return balanceOf our contract in ERC20 contract", async() => {
    //     let balanceOfERC20 = await twoKeyAcquisitionCampaignERC20.checkInventoryBalance();
    //     assert.equal(balanceOfERC20, 700, "balance should be 700");
    // })


});
