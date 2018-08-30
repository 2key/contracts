/* eslint-disable no-alert, no-console */

const { increaseTime, latestTime, duration } = require("./utils");


const TwoKeyCampaignFactory = artifacts.require("TwoKeyCampaignFactory.sol");

contract('TwoKeyCampaignFactory', async (accounts) => {
    let twoKeyCampaignFactory;

    /*
        First we deploy twoKeyCampaignFactory contract
     */
    before(async() => {
        twoKeyCampaignFactory = await TwoKeyCampaignFactory.new();
    });

    it("should return addresses of contracts", async() => {
        let addresses = await twoKeyCampaignFactory.getAddresses();
        console.log(addresses);

        assert.equal(addresses.length, 3, "should have deployed 3 contracts");
    });

});