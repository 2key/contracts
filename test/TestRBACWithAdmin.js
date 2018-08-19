const RBACWithAdmin = artifacts.require("RBACWithAdmin");

contract('RBACWithAdmin', async (accounts) => {
    let contract;

    before(async() => {
        contract = await RBACWithAdmin.new({from: accounts[0]});
    });
    it("should give admin role to deployers address", async() => {
       let isAdmin = await contract.hasRole(accounts[0], "admin");
       assert.equal(isAdmin, true, "should be the admin");
    });

    it("should give controller role to second account", async() => {
        await contract.adminAddRole(accounts[1], "controller");

        let isController = await contract.hasRole(accounts[1], "controller");

        assert.equal(isController, true, "shoud be the controller");
    });

});