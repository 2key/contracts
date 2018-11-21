const TwoKeyFetchETHPrice = artifacts.require("TwoKeyFetchETHPrice");


contract("TwoKeyFetchETHPrice", async (accounts) => {

    let instance;
    before(async()=> {
        instance = TwoKeyFetchETHPrice.new({value: 10000000});
    });

    it('should fetch price before update', async() => {
        let price = await instance.ETHUSD;
        console.log('Price is: ' + price);
    });

    it('should update price', async() => {
        await instance.doSomething();
        let price = await instance.ETHUSD;
        console.log('Price is: ' + price);
    })
});