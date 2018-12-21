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

module.exports = {
    deserializeHex
}