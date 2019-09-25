const childProcess = require('child_process');
const rimraf = require('rimraf');
const simpleGit = require('simple-git/promise');
const path = require('path');
const fs = require('fs');
const axios = require('axios');

require('dotenv').config({ path: path.resolve(process.cwd(), './.env-slack')});

const env_to_channelCode = {
    "test": "CKL4T7M2S",
    "staging": "CKKRPNR55",
    "prod": "CKHG3LS20"
};

const branch_to_env = {
    "develop": "test",
    "staging": "staging",
    "master": "prod"
};

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
const runDeployCampaignMigration = (network) => new Promise(async(resolve, reject) => {
    try {
        if (!process.env.SKIP_6MIGRATION) {
            await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--f', '6', '--to', '6', '--network', network]);
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
        await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--f', '7', '--network', network, 'update', contractName]);
        resolve(true);
    } catch (e) {
        reject(e);
    }
});

/**
 *
 * @returns {Promise<any>}
 */
const getConfigForTheBranch = () => new Promise(async(resolve,reject) => {
    try {
        let branch = await getGitBranch();
        let filePath = `./2key-protocol/dist/contracts_deployed-${branch}.json`;
        console.log(filePath);
        let file = fs.readFileSync(filePath);
        resolve(JSON.parse(file));
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
        resolve(branchStatus.current);
    } catch (e) {
        reject(e);
    }
});


const slack_message_proposal_created = async (contractName, newVersion, proposalBytecode, proposalID, network) => {
    const token = process.env.SLACK_TOKEN;

    const branch = await getGitBranch();
    const devEnv = branch_to_env[branch];

    const body = {
        channel: env_to_channelCode[devEnv],
        attachments: [
            {
                blocks: [
                    {
                        type: 'section',
                        text: {
                            type: 'mrkdwn',
                            text: `*Deployed new version of*  \`${contractName}\` *to network:* ${network} --> <@eiTan> <@Kiki> \n *New version :* \`${newVersion}\` \n *Proposal ID to be voted for:* \`${proposalID}\` \n *Proposal bytecode:* \`${proposalBytecode}\``,
                        },

                    },
                ],
            },

        ],

    };

    await axios.post('https://slack.com/api/chat.postMessage?parse=full&link_names=1', body, {
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-type': 'application/json; charset=utf-8'
        }
    }).then(
        res => {process.exit(0)},
        err => {console.log(err);process.exit(1)}
    );
};





module.exports = {
    incrementVersion,
    runProcess,
    runDeployCampaignMigration: runDeployCampaignMigration,
    runUpdateMigration,
    rmDir,
    getGitBranch,
    getConfigForTheBranch,
    slack_message_proposal_created
};
