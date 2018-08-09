const TwoKeyWhitelisted = artifacts.require("TwoKeyWhitelisted");


contract('TestTwoKeyWhitelisted', async (accounts) => {

	let whitelist;

	before(async () => {
		whitelist = await TwoKeyWhitelisted.new();
	});

    it('create and add', async () => {
        await whitelist.addToWhitelist(accounts[1], {
        	from: accounts[0]
        });

        let flagOne = await whitelist.isWhitelisted(accounts[1]);

        assert.isTrue(flagOne, "address not added");
    });

    it('add two addresses at once', async () => {
    	await whitelist.addManyToWhitelist([accounts[2], accounts[8]], {
    		from: accounts[0]
    	});

        let flagTwo = await whitelist.isWhitelisted(accounts[2]);
        let flagEight = await whitelist.isWhitelisted(accounts[8]);

        assert.isTrue(flagTwo, "address 1 of 2 not added");
        assert.isTrue(flagEight, "address 2 of 2 not added");
    });

    it("if it was not added, it is not in", async () => {
        let flagThree = await whitelist.isWhitelisted(accounts[3]);
        assert.isFalse(flagThree, "declared as whitelisted by never added");
    })

    it('remove address', async () => {
    	await whitelist.removeFromWhitelist(accounts[2], {
    		from: accounts[0]
    	});

    	let flagTwoAfterRemoving = await whitelist.isWhitelisted(accounts[2]);
        assert.isFalse(flagTwoAfterRemoving, "address was not removed");
    });
});
