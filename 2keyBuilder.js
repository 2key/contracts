const fs = require('fs');
const path = require('path');
const util = require('util');
const tar = require('tar');
const sha256 = require('js-sha256');
const IPFS = require('ipfs-http-client');
const LZString = require('lz-string');
const prompt = require('prompt');
const { networks: truffleNetworks } = require('./truffle');
const axios = require('axios');
const simpleGit = require('simple-git/promise');
const moment = require('moment');
const whitelist = require('./ContractDeploymentWhiteList.json');
const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const configPath = path.join(__dirname, 'configurationFiles');
const buildBackupPath = path.join(__dirname, 'build', 'contracts.bak');
const twoKeyProtocolDir = path.join(__dirname, '2key-protocol', 'src');
const twoKeyProtocolDist = path.join(__dirname, '2key-protocol', 'dist');
const twoKeyProtocolLibDir = path.join(__dirname, '2key-protocol', 'dist');
const twoKeyProtocolSubmodulesDir = path.join(__dirname, '2key-protocol', 'dist', 'submodules');
const contractsGit = simpleGit();
const twoKeyProtocolLibGit = simpleGit(twoKeyProtocolLibDir);
const buildArchPath = path.join(twoKeyProtocolDir, 'contracts{branch}.tar.gz');
let deployment = process.env.FORCE_DEPLOYMENT || false;

require('dotenv').config({ path: path.resolve(process.cwd(), './.env-slack')});
const { runProcess, runDeployCampaignMigration, runUpdateMigration, rmDir } = require('./helpers');

const deployedTo = {};

let contractsStatus;

const getBuildArchPath = () => {
    if(contractsStatus && contractsStatus.current) {
        return buildArchPath.replace('{branch}',`-${contractsStatus.current}`);
    }
    return buildArchPath;
};

const getContractsDeployedPath = () => {
    const result = path.join(twoKeyProtocolDir,'contracts_deployed{branch}.json');
    if(contractsStatus && contractsStatus.current) {
        return result.replace('{branch}',`-${contractsStatus.current}`);
    }
    return result;
};

const getContractsDeployedDistPath = () => {
    const result = path.join(twoKeyProtocolDist,'contracts_deployed{branch}.json');
    if(contractsStatus && contractsStatus.current) {
        return result.replace('{branch}',`-${contractsStatus.current}`);
    }
    return result;
};

const getVersionsPath = (branch = true) => {
    const result = path.join(twoKeyProtocolDir,'versions{branch}.json');
    if (branch) {
        if(contractsStatus && contractsStatus.current) {
            return result.replace('{branch}',`-${contractsStatus.current}`);
        }
        return result;
    }
    return result.replace('{branch}', '');
};




async function handleExit() {
     console.log('Do you want to accept hard reset of branch? [Y/N]');
     prompt.start();
     prompt.get(['option'], async function (err, result) {
        if(result.option == 'Y') {
            await contractsGit.reset('hard');
            await twoKeyProtocolLibGit.reset('hard');
        } else {
            console.log('Bye Bye');
        }
        process.exit();
    });
}

// process.on('exit', handleExit);
// process.on('SIGINT', handleExit);
// process.on('SIGUSR1', handleExit);
// process.on('SIGUSR2', handleExit);
// process.on('uncaughtException', handleExit);



const archiveBuild = () => new Promise(async (resolve, reject) => {
    try {
        if (fs.existsSync(buildPath)) {
            console.log('Archiving current artifacts to', getBuildArchPath());
            tar.c({
                gzip: true, sync: true, cwd: path.join(__dirname, 'build')
            }, ['contracts'])
                .pipe(fs.createWriteStream(getBuildArchPath()));


            await rmDir(buildPath);
            if (fs.existsSync(buildBackupPath)) {
                console.log('Restoring artifacts from backup', buildBackupPath);
                fs.renameSync(buildBackupPath, buildPath);
            }
        }
        resolve();
    } catch (err) {
        reject(err);
    }
});

const restoreFromArchive = () => new Promise(async (resolve, reject) => {
    try {
        if (fs.existsSync(buildPath)) {
            console.log('Backup current artifacts to', buildBackupPath);
            if (fs.existsSync(buildBackupPath)) {
                await rmDir(buildBackupPath);
            }
            fs.renameSync(buildPath, buildBackupPath);
        }
        if (fs.existsSync(getBuildArchPath())) {
            console.log('Excracting', getBuildArchPath())
            tar.x({file: getBuildArchPath(), gzip: true, sync: true, cwd: path.join(__dirname, 'build')});
        }
        resolve()
    } catch (e) {
        reject(e);
    }
});

const generateSOLInterface = () => new Promise((resolve, reject) => {
    console.log('Generating abi', deployedTo);
    if (fs.existsSync(buildPath)) {
        let contracts = {
            'contracts': {},
        };

        let singletonAddresses = [];
        const proxyFile = path.join(configPath, 'proxyAddresses.json');
        let json = {};
        let data = {};
        let proxyAddresses = {};
        if (fs.existsSync(proxyFile)) {
            proxyAddresses = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf-8' }));
        }
        readdir(buildPath).then((files) => {
            try {
                files.forEach((file) => {
                    const {
                        networks, contractName, bytecode, abi
                    } = JSON.parse(fs.readFileSync(path.join(buildPath, file), { encoding: 'utf-8' }));
                    if (whitelist[contractName]) {
                        const whiteListedContract = whitelist[contractName];
                        const proxyNetworks = proxyAddresses[contractName] || {};
                        const mergedNetworks = {};
                        Object.keys(networks).forEach(key => {
                            mergedNetworks[key] = { ...networks[key], ...proxyNetworks[key] };
                            if(proxyNetworks[key]) {
                                singletonAddresses.push(proxyNetworks[key].address);
                                singletonAddresses.push(proxyNetworks[key].implementationAddressStorage);
                            }
                        });
                        if (!contracts.contracts[whiteListedContract.file]) {
                            contracts.contracts[whiteListedContract.file] = {};
                        }
                        contracts.contracts[whiteListedContract.file][contractName] = { abi, name: contractName };
                        if (whiteListedContract.networks) {
                            contracts.contracts[whiteListedContract.file][contractName].networks = mergedNetworks;
                        }
                        if (whiteListedContract.bytecode) {
                            contracts.contracts[whiteListedContract.file][contractName].bytecode = bytecode;
                        }

                        json[contractName] = whitelist[contractName].singleton
                            ? {networks: mergedNetworks, abi, name: contractName} : {bytecode, abi, name: contractName};

                        let networkKeys = Object.keys(networks);
                        networkKeys.forEach((key) => {
                            if (Array.isArray(data[key.toString()])) {
                                data[key.toString()].push({
                                    contract : contractName,
                                    address : networks[key].address});
                            } else {
                                data[key.toString()] = [{
                                    contract : contractName,
                                    address : networks[key].address}];
                            }
                        });
                    }
                });
                const nonSingletonsBytecodes = [];
                Object.keys(contracts.contracts).forEach(submodule => {
                    if (submodule !== 'singletons') {
                        Object.values(contracts.contracts[submodule]).forEach(({ bytecode, abi }) => {
                            nonSingletonsBytecodes.push(bytecode || JSON.stringify(abi));
                        });
                    }
                });
                const nonSingletonsHash = sha256(nonSingletonsBytecodes.join(''));
                const singletonsHash = sha256(singletonAddresses.join(''));
                Object.keys(contracts.contracts).forEach(key => {
                    contracts.contracts[key]['NonSingletonsHash'] = nonSingletonsHash;
                    contracts.contracts[key]['SingletonsHash'] = singletonsHash;
                });

                let obj = {
                    'NonSingletonsHash': nonSingletonsHash,
                    'SingletonsHash': singletonsHash,
                    // 'NetworkHashes': keyHash,
                };


                contracts.contracts.singletons = Object.assign(obj, contracts.contracts.singletons);
                console.log('Writing contracts for submodules...');
                if(!fs.existsSync(path.join(twoKeyProtocolDir, 'contracts'))) {
                    fs.mkdirSync(path.join(twoKeyProtocolDir, 'contracts'));
                }
                Object.keys(contracts.contracts).forEach(file => {
                    fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts', `${file}.ts`), `export default ${util.inspect(contracts.contracts[file], {depth: 10})}`)
                });
                json = Object.assign(obj,json);
                fs.writeFileSync(getContractsDeployedPath(), JSON.stringify(json, null, 2));
                if (deployment) {
                    fs.copyFileSync(getContractsDeployedPath(),getContractsDeployedDistPath());
                }
                resolve(contracts);
            } catch (err) {
                reject(err);
            }
        });
    }
});


/**
 * Parse all arguments to check all contracts to be updated
 * @param arguments
 * @returns {*}
 */
const getAllContractsToBeUpdated = (arguments) => {
    let len = arguments.length;
    let contracts = [];
    while(arguments[len] != 'update' && len > 0) {
        contracts.push(arguments[len]);
        len--;
    }
    if(len == 0) {
        return [];
    } else if(contracts.length > 1) {
        return contracts.slice(1);
    } else {
        return contracts;
    }
};

const ipfs = new IPFS('ipfs.2key.net', 443, { protocol: 'https' });

const ipfsGet = (hash) => new Promise((resolve, reject) => {
    ipfs.get(hash, (err, res) => {
        if (err) {
            reject(err);
        } else {
            resolve(res[0] && res[0].content.toString());
        }
    });
});

const ipfsAdd = (data) => new Promise((resolve, reject) => {
    ipfs.add(ipfs.types.Buffer.from(data), { pin: deployment }, (err, res) => {
        if (err) {
            reject(err);
        } else {
            resolve(res);
        }
    });
});

const updateIPFSHashes = async(contracts) => {
    const nonSingletonHash = contracts.contracts.singletons.NonSingletonsHash;
    console.log(nonSingletonHash);


    let versionsList = {};

    let existingVersionHandlerFile = {};
    try {
        existingVersionHandlerFile = JSON.parse(fs.readFileSync(getVersionsPath()), { encoding: 'utf8' });
        console.log('EXISTING VERSIONS', existingVersionHandlerFile);
    } catch (e) {
        console.log('VERSIONS ERROR', e);
    }

    const { TwoKeyVersionHandler: currentVersionHandler } = existingVersionHandlerFile;

    if (currentVersionHandler) {
        versionsList = JSON.parse((await ipfsGet(currentVersionHandler)).toString());
        console.log('VERSION LIST', versionsList);
    }
    versionsList[nonSingletonHash] = {};
    const files = (await readdir(twoKeyProtocolSubmodulesDir)).filter(file => file.endsWith('.js'));
    for (let i = 0, l = files.length; i < l; i++) {
        const js = fs.readFileSync(path.join(twoKeyProtocolSubmodulesDir, files[i]), { encoding: 'utf-8' });
        console.time('Compress');
        const compressedJS = LZString.compressToUTF16(js);
        console.timeEnd('Compress');
        console.log(files[i], (js.length / 1024).toFixed(3), (compressedJS.length / 1024).toFixed(3));
        console.time('Upload');
        const [{ hash }] = await ipfsAdd(compressedJS);
        console.timeEnd('Upload');
        versionsList[nonSingletonHash][files[i].replace('.js', '')] = hash;
    }
    console.log(versionsList);
    const [{ hash: newTwoKeyVersionHandler }] = await ipfsAdd(JSON.stringify(versionsList));
    fs.writeFileSync(getVersionsPath(), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));
    fs.writeFileSync(getVersionsPath(false), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));
    console.log('TwoKeyVersionHandler', newTwoKeyVersionHandler);
};

const commitAndPushContractsFolder = async(commitMessage) => {
    const contractsStatus = await contractsGit.status();
    await contractsGit.add(contractsStatus.files.map(item => item.path));
    await contractsGit.commit(commitMessage);
    await contractsGit.push('origin', contractsStatus.current);
};

async function deploy() {
    try {
        deployment = true;

        await contractsGit.fetch();
        await contractsGit.submoduleUpdate();
        let twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
        if (twoKeyProtocolStatus.current !== contractsStatus.current) {
            const twoKeyProtocolBranches = await twoKeyProtocolLibGit.branch();
            if (twoKeyProtocolBranches.all.find(item => item.includes(contractsStatus.current))) {
                await twoKeyProtocolLibGit.checkout(contractsStatus.current);
            } else {
                await twoKeyProtocolLibGit.checkoutLocalBranch(contractsStatus.current);
            }
        }
        await contractsGit.submoduleUpdate();
        await twoKeyProtocolLibGit.reset('hard');
        twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
        const localChanges = contractsStatus.files
        // .filter(item => !(item.path.includes('2key-protocol-npm')
            .filter(item => !(item.path.includes('dist') || item.path.includes('contracts.ts') || item.path.includes('contracts_deployed')
                || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
        if (contractsStatus.behind || localChanges.length) {
            console.log('You have unsynced changes!', localChanges);
            process.exit(1);
        }
        console.log(process.argv);
        const local = process.argv[2].includes('local');
        if (!local && !process.env.SKIP_TEST) {
            await test();
        }

        await restoreFromArchive();

        const networks = process.argv[2].split(',');
        const network = networks.join('/');
        const now = moment();
        const commit = `SOL Deployed to ${network} ${now.format('lll')}`;
        const tag = `${network}-${now.format('YYYYMMDDHHmmss')}`;

        const l = networks.length;
        for (let i = 0; i < l; i += 1) {
            /* eslint-disable no-await-in-loop */
            let contractsToBeUpdated = getAllContractsToBeUpdated(process.argv);
            console.log('Contracts to be updated: ' + contractsToBeUpdated.length);
            if(contractsToBeUpdated.length > 0) {
                for(let j=0; j<contractsToBeUpdated.length; j++) {
                    /* eslint-disable no-await-in-loop */
                    await runUpdateMigration(networks[i], contractsToBeUpdated[j]);
                }
            } else {
                await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--network', networks[i]].concat(process.argv.slice(3)));
                deployedTo[truffleNetworks[networks[i]].network_id.toString()] = truffleNetworks[networks[i]].network_id;
            }
            await runDeployCampaignMigration(networks[i]);
            /* eslint-enable no-await-in-loop */
        }

        const contracts = await generateSOLInterface();
        await archiveBuild();
        await commitAndPushContractsFolder(`Contracts deployed to ${network} ${now.format('lll')}`);
        console.log('Changes commited');
        await restoreFromArchive();
        await buildSubmodules(contracts);
        if (!local) {
            await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'));
        }
        await archiveBuild();
        contractsStatus = await contractsGit.status();
        twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
        console.log(commit, tag);

        await twoKeyProtocolLibGit.add(twoKeyProtocolStatus.files.map(item => item.path));
        await twoKeyProtocolLibGit.commit(commit);
        await commitAndPushContractsFolder(commit);
        await twoKeyProtocolLibGit.push('origin', contractsStatus.current);

        /**
         * Npm patch & public
         * Get version of package
         * put the tag
         */
        if(!local || process.env.FORCE_NPM) {
            process.chdir(twoKeyProtocolDist);
            if (process.env.NODE_ENV === 'production') {
                await runProcess('npm', ['version', 'patch']);
            } else {
                const { version } = JSON.parse(fs.readFileSync(path.join(twoKeyProtocolDist, 'package.json'), 'utf8'));
                console.log(version);
                const versionArray = version.split('-')[0].split('.');
                console.log(versionArray);
                const patch = parseInt(versionArray.pop(), 10) + 1;
                console.log(patch);
                versionArray.push(patch);
                const newVersion = `${versionArray.join('.')}-${contractsStatus.current}`;
                console.log(newVersion);
                await runProcess('npm', ['version', newVersion])
            }
            const json = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            let npmVersionTag = json.version;
            console.log(npmVersionTag);
            process.chdir('../../');
            await contractsGit.addTag('v'+npmVersionTag.toString());
            await twoKeyProtocolLibGit.pushTags('origin');
            await contractsGit.pushTags('origin');
            process.chdir(twoKeyProtocolDist);
            if (process.env.NODE_ENV === 'production') {
                await runProcess('npm', ['publish']);
            } else {
                await runProcess('npm', ['publish', '--tag', contractsStatus.current]);
            }
            await twoKeyProtocolLibGit.push('origin', contractsStatus.current);
            process.chdir('../../');
            //Run slack message
            await slack_message(npmVersionTag);
        } else {
            process.exit(0);
        }
    } catch (e) {
        if (e.output) {
            e.output.forEach((buff) => {
                if (buff && buff.toString) {
                    console.log(buff.toString('utf8'));
                }
            });
        } else {
            console.warn('Error', e);
        }
        await contractsGit.reset('hard');
    }
}

/**
 * Function to send message to slack channel
 * @param message
 */
const slack_message = async (newVersion) => {
    const token = process.env.SLACK_TOKEN;

    let commitHash = require('child_process')
        .execSync('git rev-parse HEAD')
        .toString().trim();


    let commitHash2keyProtocol = require('child_process')
        .execSync('cd 2key-protocol/dist && git rev-parse HEAD')
        .toString().trim();


    const body = {
        channel: 'CKL4T7M2S',
        attachments: [
            {
                blocks: [
                    {
                        type: 'section',
                        text: {
                            type: 'mrkdwn',
                            text: `*2KEY-PROTOCOL DEPLOYED NEW VERSION* :  *${newVersion.toUpperCase()}*`,
                        }
                    },
                    {
                        type: 'divider',
                    },
                    {
                        type: 'section',
                        text: {
                            type: 'mrkdwn',
                            text: `*Last commit contracts repo: * https://github.com/2key/contracts/commit/${commitHash}`,
                        },
                    },
                    {
                        type: 'section',
                        text: {
                            type: 'mrkdwn',
                            text: `*Last commit 2key-protocol repo: * https://github.com/2key/2key-protocol/commit/${commitHash2keyProtocol.toUpperCase()}`,
                        },
                    },
                ]
            }
        ]
    };

    await axios.post('https://slack.com/api/chat.postMessage', body, {
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-type': 'application/json; charset=utf-8'
        }
    }).then(
        res => {process.exit(0)},
        err => {console.log(err);process.exit(1)}
    );
};

const test = () => new Promise(async (resolve, reject) => {
    try {
        await runProcess('node', ['-r', 'dotenv/config', './node_modules/.bin/mocha', '--exit', '--bail', '-r', 'ts-node/register', '2key-protocol/test/index.spec.ts']);
        resolve();
    } catch (err) {
        reject(err);
    }

});

const buildSubmodules = async(contracts) => {
    await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'), ['--config', './webpack.config.submodules.js', '--mode production', '--colors']);
    // TODO: Add implementation for updateIPFSHashes
    await updateIPFSHashes(contracts);
};

const getMigrationsList = () => {
    const migrationDir = path.join(__dirname, 'migrations');
    return fs.readdirSync(migrationDir);
};

const runMigration = async (index, network, updateArchive) => {
    await runProcess(
      path.join(__dirname, 'node_modules/.bin/truffle'),
      ['migrate', '--f', index, '--to', index, '--network', network].concat(process.argv.slice(4))
    );
    if (updateArchive) {
        await archiveBuild();
        let deploy = {};
        try {
            deploy = JSON.parse(fs.readFileSync(path.join(__dirname, 'deploy.json'), { encoding: 'utf-8' }))
        } catch (e) {
        }
        deploy[network] = index;
        fs.writeFileSync(path.join(__dirname, 'deploy.json'), JSON.stringify(deploy), { encoding: 'utf-8' });
    }
};

const getStartMigration = (network) => {
    let deploy = {};
    try {
        deploy = JSON.parse(fs.readFileSync(path.join(__dirname, 'deploy.json'), { encoding: 'utf-8' }))
    } catch (e) {
    }
    return deploy[network] ? deploy[network] + 1 :  1;
};

async function main() {
    contractsStatus = await contractsGit.status(); // Fetching branch
    const mode = process.argv[2];
    switch (mode) {
        case '--update':
            try {

                await restoreFromArchive();
                const networks = process.argv[3];
                for(let i=4; i<process.argv.length; i++) {
                    let contractName = process.argv[i];
                    let str = contractName.toString()+".json";
                    console.log(str);
                    fs.unlinkSync(path.join(buildPath, str));
                    await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'),['migrate',`--network=${networks}`,'--f', 5,'update',contractName]);
                }
                await generateSOLInterface();
                process.exit(0);
            } catch (err) {
                process.exit(1);
            }
            break;
        case '--migrate':
            try {
                const networks = process.argv[3].split(',');

                const l = networks.length;
                for (let i = 0; i < l; i += 1) {
                    for (let j = getStartMigration(networks[i]), m = getMigrationsList().length; j <= m; j += 1) {
                        /* eslint-disable no-await-in-loop */
                        await runMigration(j, networks[i], false);
                        /* eslint-enable no-await-in-loop */
                    }
                    deployedTo[truffleNetworks[networks[i]].network_id.toString()] = truffleNetworks[networks[i]].network_id;
                }

                await generateSOLInterface();
                process.exit(0);
            } catch (err) {
                process.exit(1);
            }
            break;
        case '--migration6': {
            try {
                const networks = process.argv[3].split(',');
                await runDeployCampaignMigration(networks[0]);
                process.exit(0);
            } catch (e) {
                console.log(e);
            }
            break;
        }
        case '--generate':
            await generateSOLInterface();
            process.exit(0);
            break;
        case '--archive':
            archiveBuild();
            process.exit(0);
            break;
        case '--extract':
            restoreFromArchive();
            process.exit(0);
            break;
        case '--submodules':
            const contracts = await generateSOLInterface();
            await buildSubmodules(contracts);
            process.exit(0);
            break;
        case '--mig':
            getMigrationsList();
            process.exit(0);
            break;
        default:
            await deploy();
            process.exit(0);
    }
}

main().catch((e) => {
    console.log(e);
    process.exit(1);
});
