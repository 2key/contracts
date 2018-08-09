const { increaseTime, latestTime, duration } = require("./utils");
require('truffle-test-utils').init();
const _ = require('lodash');

const HOUR = 3600;

const TwoKeyEscrow = artifacts.require("TwoKeyEscrow");
const TwoKeyWhitelisted = artifacts.require("TwoKeyWhitelisted");
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");

const ERC721Mock = artifacts.require("ERC721TokenMock");
const ERC20Mock = artifacts.require("ERC20TokenMock");

contract('TwoKeyEscrow', async (accounts) => {

    let whitelistConverter, 
        escrow,
        erc721, 
        erc20;


    const coinbase = accounts[0];
    const tokenIndex = "123";
    const contractor = accounts[2];
    const moderator = accounts[1];
    const escrowCreator = accounts[3];
    const buyer = accounts[4];
    const tokenIDNFT = "1";
    const tokenIDFT = "2";


    before(async () => {
        eventSource = await TwoKeyEventSource.new();
        whitelistConverter = await TwoKeyWhitelisted.new();
        

        erc721 = await ERC721Mock.new("NFT", "NFT");
        // await erc721.mint(contractor, tokenIndex, {
        //     from: coinbase,
        // });
        erc20 = await ERC20Mock.new();
    });

    it("transfer fungible to escrow", async () => {

        const openingTime = latestTime() + duration.minutes(1);
        const durationEscrow = duration.minutes(5);
        console.log('times', openingTime, typeof openingTime, durationEscrow, typeof durationEscrow);


        escrow = await TwoKeyEscrow.new(
            eventSource.address, 
            contractor, 
            moderator, 
            buyer,
            openingTime, 
            durationEscrow,
            whitelistConverter, 
            {
                from: escrowCreator
            }
        );

        await erc20.transfer(contractor, 200, {
            from: coinbase
        });

        let bal = await erc20.balanceOf(contractor);
        assert.equal(bal.toNumber(), 200, 'nothing tranferred to contractor');


        await erc20.approve(escrow.address, 20, {
            from: contractor,
        });

        await escrow.addFungibleChild(tokenIDFT, erc20, 20, {
            from: campaignCreator
        });
    //     await campaign.setPriceFungible(tokenIDFT, erc20, ether(5), {
    //         from: campaignCreator
    //     });
    });
  
    it("cancel escrow", async () => {

    });
   
});
