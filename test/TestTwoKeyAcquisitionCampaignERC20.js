const { increaseTime, latestTime, duration, free_join, free_join_take, privateToPublic, validate_join, generatePrivateKey } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');
const BigNumber = web3.BigNumber;


const MINUTE = 60;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;

const date = new Date();
const timestamp = date.getTime();


const getDays = ((days) => {
   return days*DAY;
});


/// contracts
const TwoKeyConversionHandler = artifacts.require("TwoKeyConversionHandler");
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyAcquisitionCampaignERC20 = artifacts.require("TwoKeyAcquisitionCampaignERC20");
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");

/// tokens
const StandardToken = artifacts.require("StandardToken");


const [user1, user2, user3, user4, user5, user6, user7, user8, user9]
    = [accounts[1],accounts[2],accounts[3], accounts[4], accounts[5], accounts[6], accounts[7], accounts[8], accounts[9]];


const tokenDistributionDate = timestamp;
const maxDistributionDateShiftInDays = 180;
const bonusTokensVestingMonths = 6;
const bonusTokensVestingStartShiftInDaysFromDistributionDate = 1;


let acquisitionInstance;
let conversionHandlerInstance;
let twoKeyEconomyInstance;

contract('TwoKeyAcquisitionCampaignERC20', async (accounts) => {

    before(async () => {
        conversionHandlerInstance = TwoKeyConversionHandler.new(tokenDistributionDate,
                                                                maxDistributionDateShiftInDays,
                                                                bonusTokensVestingMonths,
                                                                bonusTokensVestingStartShiftInDaysFromDistributionDate
                                                                );

    });


});
