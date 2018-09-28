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
       let hex = await serializationContract.encode(accounts[0],12345,123456);
       console.log("hex is: " + hex);
        console.log("ACcounts[0] = " + accounts[0]);
       let address = hex.slice(0,42);
       console.log(address);

       let number = hex.slice(42,42+64);

       console.log(parseInt(number,16));

       let number1 = hex.slice(42+64, 170);
       console.log(parseInt(number1,16));

    });
});
