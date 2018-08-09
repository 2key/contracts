const TwoKeyReg = artifacts.require("TwoKeyReg");

contract('TwoKeyReg', async (accounts) => {
  it("add", async () => {
    let reg = await TwoKeyReg.new()
    let address = accounts[0]
    let name = 'account0-0'
    
    await reg.addName(name, {from: address})

    let test_address = await reg.getName2Owner(name)
    assert.equal(address, test_address, 'address stored for name not the same as address retrieved');

    let test_name = await reg.getOwner2Name(address)
    assert.equal(name, test_name, 'name stored for address is wrong');
  });
});