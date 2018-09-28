const TwoKeyWhitelisted = artifacts.require("TwoKeyWhitelisted");
const {deserializeHex} = require("./helpers/deserialize.js");


contract('TestTwoKeyWhitelisted', async (accounts) => {

	let whitelistedContract;

	before(async () => {
		whitelistedContract = await TwoKeyWhitelisted.new();
	});

	it("should well encode and decode data", async() => {
	   let converterAddress = accounts[0];
	   let conversionCreatedAt = 12345;
	   let conversionAmountETH = 123456;

	   let encoded = await whitelistedContract.encode(converterAddress, conversionCreatedAt, conversionAmountETH);

	   let decoded = deserializeHex(encoded);
	   console.log(decoded);
    });

});
