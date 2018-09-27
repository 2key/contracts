const Serialize = artifacts.require("Serialize");
const {convert} = require("./helpers/deserialize.js");
contract('Serialize', async (accounts) => {
    let serializationContract;
    before(async() => {
        serializationContract = await Serialize.new();
    });
    it("should have been deployed", async() => {
        console.log("Address of generation contract is: " + serializationContract.address);
    });

    it("should generate json", async() => {
       let hash = await serializationContract.getBytes(accounts[0],12345,123456);
       console.log("Hash is: " + hash);
        console.log(accounts[0]);
       let deserailized = convert(hash);
       console.log(deserailized);
    });
});
