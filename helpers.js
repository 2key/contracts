const childProcess = require('child_process');
const rimraf = require('rimraf');
const simpleGit = require('simple-git/promise');


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

const runProcess = (app, args) => new Promise((resolve, reject) => {
    console.log('Run process', app, args && args.join(' '));
    const proc = childProcess.spawn(app, args, {stdio: [process.stdin, process.stdout, process.stderr]});
    proc.on('close', async (code) => {
        console.log('process exit with code', code);
        if (code === 0) {
            resolve(code);
        } else {
            reject(code);
        }
    });
});

/**
 * This is function to run when we want to update our campaigns
 * @param network
 * @returns {Promise<any>}
 */
const runMigration4 = (network) => new Promise(async(resolve, reject) => {
    try {
        if (!process.env.SKIP_4MIGRATION) {
            await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--f', '4', '--network', network]);
            resolve(true);
        } else {
            resolve(true);
        }
    } catch (e) {
        reject(e);
    }
});

/**
 * If there's a need to update, we'll run this function
 * @param network
 * @param contractName
 * @returns {Promise<any>}
 */
const runUpdateMigration = (network, contractName) => new Promise(async(resolve,reject) => {
    try {
        console.log("Running update migration");
        await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--f', '5', '--network', network, 'update', contractName]);
        resolve(true);
    } catch (e) {
        reject(e);
    }
});


/**
 * Remove direcotry
 * @param dir
 * @returns {Promise<any>}
 */
const rmDir = (dir) => new Promise((resolve) => {
    rimraf(dir, () => {
        resolve();
    })
});

/**
 *
 * @returns {Promise<any>}
 */
const getGitBranch = () => new Promise(async(resolve,reject) => {
    try {
        const currentRepo = simpleGit();
        let branchStatus = await currentRepo.status();
        return branchStatus.current;
    } catch (e) {
        reject(e);
    }
});





module.exports = {
    incrementVersion,
    runProcess,
    runMigration4,
    runUpdateMigration,
    rmDir,
    getGitBranch
};
