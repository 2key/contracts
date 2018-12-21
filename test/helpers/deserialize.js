/**
 *
 * @param hex
 * @returns {{converterAddress, conversionCreatedAt: number, conversionAmountEth: number}}
 */
function deserializeHex(hex) {
    let converterAddress = hex.slice(0,42);
    let conversionCreatedAt = parseInt(hex.slice(42, 42+64),16);
    let conversionAmountETH = parseInt(hex.slice(42+64, 42+64+64),16);

    let data = {
        "converterAddress" : converterAddress,
        "conversionCreatedAt" : conversionCreatedAt,
        "conversionAmountEth" : conversionAmountETH
    };

    return data;
}

let testData = "0xca35b7d915458ef540ade6068dfe2f44e8fa733c00000000000000000000000000000000000000000000000000000000000000c8ca35b7d915458ef540ade6068dfe2f44e8fa733c00000000000000000000000000000000000000000000000000000000000030390000000000000000000000000000000000000000000000000000000000bc6143000000000000000000000000000000000000000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006";
function decode(testData) {
    let contractor = testData.slice(0,42);
    let inventoryAmount = parseInt(testData.slice(42, 42+64),16);
    let assetContractAddress = '0x' + testData.slice(42+64, 42+64+42);
    let campaignStartTime = parseInt(testData.slice(42+64+40,42+64+40+64),16);
    let campaignEndTime = parseInt(testData.slice(42+64+40+64, 42+64+40+64+64),16);
    let numberOfTokensPerConversion = parseInt(testData.slice(42+64+40+64+64,42+64+40+64+64+64),16);
    let numberOfConversions = parseInt(testData.slice(42+64+40+64+64+64, 42+64+40+64+64+64+64),16);
    let maxNumberOfConversions = parseInt(testData.slice(42+64+40+64+64+64+64, 42+64+40+64+64+64+64+64),16);

    let obj = {
        contractor: contractor,
        inventoryAmount : inventoryAmount,
        assetContractAddress : assetContractAddress,
        campaignStartTime : campaignStartTime,
        campaignEndTime : campaignEndTime,
        numberOfTokensPerConverter : numberOfTokensPerConversion,
        numberOfConversions : numberOfConversions,
        maxNumberOfConversions : maxNumberOfConversions
    };
    console.log(obj);
}



module.exports = {
    deserializeHex, decode
};