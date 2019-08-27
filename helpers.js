const incrementVersion = ((version) => {
    if(version == "") {
        version = "1.0.0";
    }
    let vParts = version.split('.');
    if(vParts.length < 2) {
        vParts = "1.0.0".split('.');
    }
    // assign each substring a position within our array
    let partsArray = {
        major : vParts[0],
        minor : vParts[1],
        patch : vParts[2]
    };
    // target the substring we want to increment on
    partsArray.patch = parseFloat(partsArray.patch) + 1;
    // set an empty array to join our substring values back to
    let vArray = [];
    // grabs each property inside our partsArray object
    for (let prop in partsArray) {
        if (partsArray.hasOwnProperty(prop)) {
            // add each property to the end of our new array
            vArray.push(partsArray[prop]);
        }
    }
    // join everything back into one string with a period between each new property
    let newVersion = vArray.join('.');
    return newVersion;
});


module.exports = {
    incrementVersion
};
