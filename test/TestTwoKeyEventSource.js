require('truffle-test-utils').init();

/// required contracts in order to deploy TwoKeyEventSource
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");


/// required Mock ERC20 contract in order to deploy & test TwoKeyEventSource
const ERC20Mock = artifacts.require("ERC20TokenMock");



contract("TwoKeyEventSource", async (accounts) => {

	/// contract instances
	let twoKeyAdmin,
		eventSource,
		upgradeableExchange,
		economy,
		erc20;


	/// accounts
    const coinbase = accounts[0];
	const electorateAdmins = accounts[1];
	const walletExchange = accounts[2];
	const subAdminAddress = accounts[3];



    before(async()=> {

        erc20 = await ERC20Mock.new({
            from: coinbase
        });

        upgradeableExchange = await TwoKeyUpgradableExchange.new(100, walletExchange, erc20.address);
        economy = await TwoKeyEconomy.new();
        twoKeyAdmin = await TwoKeyAdmin.new(economy.address, electorateAdmins, upgradeableExchange.address);

        eventSource = await TwoKeyEventSource.new(twoKeyAdmin.address);
	});

	it("should have deployed all contracts", async () => {
		console.log("[TwoKeyUpgradeableExchange] : " + upgradeableExchange.address);
		console.log("[TwoKeyEconomy] : " + economy.address);
		console.log("[TwoKeyAdmin] : " + twoKeyAdmin.address);
		console.log("[TwoKeyEventSource] : " + eventSource.address);
	});

	it("should be admin permission", async() => {
        let adminAddress = await eventSource.getAdmin();
    	assert.equal(adminAddress, twoKeyAdmin.address, "addresses should be same");
	});

	/// after creating the account in the way we've done, our new adminAddress is not returned when we do web3.eth.getAccounts()
	//  because this creates an account that is not associated with your node. Need to research how to add it to accounts
	it("admin should add subadmins", async() => {
		try {
            await eventSource.addAuthorizedAddress(subAdminAddress, {from: twoKeyAdmin.address});
        } catch (error) {
			console.log(error);
			assert.fail();
		}

		let canEmit = await eventSource.checkIsAuthorized(subAdminAddress);
		assert.equal(canEmit, true, "should be true");
	});
});
