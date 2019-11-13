const fs = require('fs');
const path = require('path');
const util = require('util');
const tar = require('tar');
const sha256 = require('js-sha256');
const LZString = require('lz-string');
const { networks: truffleNetworks } = require('./truffle');
const simpleGit = require('simple-git/promise');
const moment = require('moment');
const whitelist = require('./ContractDeploymentWhiteList.json');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build');
const contractsBuildPath = path.join(__dirname, 'build', 'contracts');
const buildBackupPath = path.join(__dirname, 'build', 'contracts.bak');
const twoKeyProtocolDir = path.join(__dirname, '2key-protocol', 'src');
const twoKeyProtocolDist = path.join(__dirname, '2key-protocol', 'dist');
const twoKeyProtocolLibDir = path.join(__dirname, '2key-protocol', 'dist');
const twoKeyProtocolSubmodulesDir = path.join(__dirname, '2key-protocol', 'dist', 'submodules');
const contractsGit = simpleGit();
const twoKeyProtocolLibGit = simpleGit(twoKeyProtocolLibDir);
const twoKeyProtocolSrcGit = simpleGit(twoKeyProtocolDir);

const buildArchPath = path.join(twoKeyProtocolDir, 'contracts{branch}.tar.gz');
let deployment = process.env.FORCE_DEPLOYMENT || false;

const { runProcess, runDeployCampaignMigration, runUpdateMigration, rmDir, slack_message, sortMechanism, ipfsAdd, ipfsGet } = require('./helpers');


const branch_to_env = {
    "develop": "test",
    "staging": "staging",
    "master": "prod"
};

const deployedTo = {};

let contractsStatus;


/**
 * Function which will get the difference between the latest tags depending on current branch we're using. Either on merge requests or on current branch.
 * @returns {Promise<void>}
 */
const getDiffBetweenLatestTags = async () => {
    const tagsDevelop = (await contractsGit.tags()).all.filter(item => item.endsWith('-develop')).sort(sortMechanism);
    let latestTagDev = tagsDevelop[tagsDevelop.length-1];

    const tagsStaging = (await contractsGit.tags()).all.filter(item => item.endsWith('-staging')).sort(sortMechanism);
    let latestTagStaging = tagsStaging[tagsStaging.length-1];

    let status = await contractsGit.status();
    let diffParams = status.current == 'staging' ? [latestTagDev,latestTagStaging] : [latestTagDev];
    let diffAllContracts = (await contractsGit.diffSummary(diffParams)).files.filter(item => item.file.endsWith('.sol')).map(item => item.file);

    let singletonsChanged = diffAllContracts.filter(item => item.includes('/singleton-contracts/')).map(item => item.split('/').pop().replace(".sol",""));
    let campaignsChanged = diffAllContracts.filter(item => item.includes('/acquisition-campaign-contracts/')|| item.includes('/campaign-mutual-contracts/') || item.includes('/donation-campaign-contracts/')).map(item => item.split('/').pop().replace(".sol",""));
    return [singletonsChanged, campaignsChanged];
};

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


const archiveBuild = () => tar.c({ gzip: true, file: getBuildArchPath(), cwd: __dirname }, ['build']);

const restoreFromArchive = () => {
    console.log("restore",__dirname);
    return tar.x({file: getBuildArchPath(), gzip: true, cwd: __dirname});
}

const generateSOLInterface = () => new Promise((resolve, reject) => {
    console.log('Generating abi', deployedTo);
    if (fs.existsSync(buildPath)) {
        let contracts = {
            'contracts': {},
        };

        let singletonAddresses = [];
        const proxyFile = path.join(buildPath, 'proxyAddresses.json');
        let json = {};
        let data = {};
        let proxyAddresses = {};
        if (fs.existsSync(proxyFile)) {
            proxyAddresses = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf-8' }));
        }
        readdir(contractsBuildPath).then((files) => {
            try {
                files.forEach((file) => {
                    const {
                        networks, contractName, bytecode, abi
                    } = JSON.parse(fs.readFileSync(path.join(contractsBuildPath, file), { encoding: 'utf-8' }));
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
        const [{ hash }] = await ipfsAdd(compressedJS, deployment);
        console.timeEnd('Upload');
        versionsList[nonSingletonHash][files[i].replace('.js', '')] = hash;
    }
    console.log(versionsList);
    const [{ hash: newTwoKeyVersionHandler }] = await ipfsAdd(JSON.stringify(versionsList), deployment);
    fs.writeFileSync(getVersionsPath(), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));
    fs.writeFileSync(getVersionsPath(false), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));
    console.log('TwoKeyVersionHandler', newTwoKeyVersionHandler);
};

/**
 *
 * @param commitMessage
 * @returns {Promise<void>}
 */
const commitAndPushContractsFolder = async(commitMessage) => {
    const contractsStatus = await contractsGit.status();
    await contractsGit.add(contractsStatus.files.map(item => item.path));
    await contractsGit.commit(commitMessage);
    await contractsGit.push('origin', contractsStatus.current);
};

/**
 *
 * @param commitMessage
 * @returns {Promise<void>}
 */
const commitAndPush2KeyProtocolSrc = async(commitMessage) => {
    const status = await twoKeyProtocolSrcGit.status();
    await twoKeyProtocolSrcGit.add(status.files.map(item => item.path));
    await twoKeyProtocolSrcGit.commit(commitMessage);
    await twoKeyProtocolSrcGit.push('origin', status.current);
};

/**
 *
 * @param commitMessage
 * @returns {Promise<void>}
 */
const commitAndPush2keyProtocolLibGit = async(commitMessage) => {
    const status = await twoKeyProtocolLibGit.status();
    await twoKeyProtocolLibGit.add(status.files.map(item => item.path));
    await twoKeyProtocolLibGit.commit(commitMessage);
    await twoKeyProtocolLibGit.push('origin', status.current);
};

const pushTagsToGithub = (async (npmVersionTag) => {
    await contractsGit.addTag('v'+npmVersionTag.toString());
    await contractsGit.pushTags('origin');

    await twoKeyProtocolLibGit.pushTags('origin');

    await twoKeyProtocolSrcGit.addTag('v'+npmVersionTag.toString());
    await twoKeyProtocolSrcGit.pushTags('origin');
})



async function deployUpgrade(networks) {
    console.log(networks);
    const l = networks.length;
    for (let i = 0; i < l; i += 1) {
        /* eslint-disable no-await-in-loop */
        let [singletonsToBeUpgraded, campaignsToBeUpgraded] = await getDiffBetweenLatestTags();
        console.log('Singletons to be upgraded: ', singletonsToBeUpgraded);
        console.log('Campaigns to be upgraded: ', campaignsToBeUpgraded);
        if(singletonsToBeUpgraded.length > 0) {
            for(let j=0; j<singletonsToBeUpgraded.length; j++) {
                /* eslint-disable no-await-in-loop */
                console.log(networks[i], singletonsToBeUpgraded[j]);
                await runUpdateMigration(networks[i], singletonsToBeUpgraded[j]);
            }
        }
        if(campaignsToBeUpgraded.length > 0) {
            await runDeployCampaignMigration(networks[i]);
        }
        /* eslint-enable no-await-in-loop */
    }
}

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
        const localChanges = contractsStatus.files.filter(item => !(item.path.includes('dist') || item.path.includes('contracts.ts') || item.path.includes('contracts_deployed')
                || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
        if (contractsStatus.behind || localChanges.length) {
            console.log('You have unsynced changes!', localChanges);
            process.exit(1);
        }
        console.log(process.argv);

        const local = process.argv[2].includes('local'); //If we're deploying to local network

        await restoreFromArchive();

        const networks = process.argv[2].split(',');
        const network = networks.join('/');
        const now = moment();
        const commit = `SOL Deployed to ${network} ${now.format('lll')}`;

        if(!process.argv.includes('protocol-only')) {
            if(process.argv.includes('update')) {
                await deployUpgrade(networks);
            } else {
                await deployContracts(networks, true);
            }
        }

        const contracts = await generateSOLInterface();
        await archiveBuild();

        await commitAndPushContractsFolder(`Contracts deployed to ${network} ${now.format('lll')}`);
        await commitAndPush2KeyProtocolSrc(`Contracts deployed to ${network} ${now.format('lll')}`);
        console.log('Changes commited');
        // await restoreFromArchive();
        await buildSubmodules(contracts);
        if (!local) {
            await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'));
        }
        // await archiveBuild();
        contractsStatus = await contractsGit.status();
        await commitAndPushContractsFolder(commit);
        await commitAndPush2KeyProtocolSrc(commit);
        await commitAndPush2keyProtocolLibGit(commit);
        /**
         * Npm patch & public
         * Get version of package
         * put the tag
         */
        if(!local || process.env.FORCE_NPM) {
            process.chdir(twoKeyProtocolDist);
            const oldVersion = JSON.parse(fs.readFileSync('package.json', 'utf8')).version;
            if (process.env.NODE_ENV === 'production') {
                await runProcess('npm', ['version', 'patch']);
            } else {
                const { version } = JSON.parse(fs.readFileSync(path.join(twoKeyProtocolDist, 'package.json'), 'utf8'));
                const versionArray = version.split('-')[0].split('.');
                const patch = parseInt(versionArray.pop(), 10) + 1;
                versionArray.push(patch);
                const newVersion = `${versionArray.join('.')}-${contractsStatus.current}`;
                await runProcess('npm', ['version', newVersion])
            }
            const json = JSON.parse(fs.readFileSync('package.json', 'utf8'));
            let npmVersionTag = json.version;
            console.log(npmVersionTag);
            process.chdir('../../');
            // Push tags
            await pushTagsToGithub(npmVersionTag);

            process.chdir(twoKeyProtocolDist);
            if (process.env.NODE_ENV === 'production') {
                await runProcess('npm', ['publish']);
            } else {
                await runProcess('npm', ['publish', '--tag', contractsStatus.current]);
            }
            await twoKeyProtocolLibGit.push('origin', contractsStatus.current);
            process.chdir('../../');
            //Run slack message
            await slack_message('v'+npmVersionTag.toString(), 'v'+oldVersion.toString(), branch_to_env[contractsStatus.current]);
            // Add tenderly to CI/CD
            await runProcess('tenderly',['push', '--tag', npmVersionTag]);
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
        await restoreFromArchive();
    }
};

const getStartMigration = (network) => {
    let deploy = {};
    if (process.argv.includes('--reset')) {
        return 1;
    }
    try {
        deploy = JSON.parse(fs.readFileSync(path.join(__dirname, 'deploy.json'), { encoding: 'utf-8' }))
    } catch (e) {
    }
    return deploy[network] ? deploy[network] + 1 :  1;
};

const deployContracts = async (networks, updateArchive) => {
    const l = networks.length;
    for (let i = 0; i < l; i += 1) {
        for (let j = getStartMigration(networks[i]), m = getMigrationsList().length; j <= m; j += 1) {
            /* eslint-disable no-await-in-loop */
            await runMigration(j, networks[i], updateArchive);
            /* eslint-enable no-await-in-loop */
        }
        deployedTo[truffleNetworks[networks[i]].network_id.toString()] = truffleNetworks[networks[i]].network_id;
    }
};


async function main() {
    contractsStatus = await contractsGit.status(); // Fetching branch
    const mode = process.argv[2];
    switch (mode) {
        case '--migrate':
            try {
                const networks = process.argv[3].split(',');
                await deployContracts(networks, false);
                await generateSOLInterface();
                process.exit(0);
            } catch (err) {
                process.exit(1);
            }
            break;
        case '--generate':
            await generateSOLInterface();
            process.exit(0);
            break;
        case '--archive':
            await archiveBuild();
            process.exit(0);
            break;
        case '--extract':
            await restoreFromArchive();
            process.exit(0);
            break;
        case '--submodules':
            const contracts = await generateSOLInterface();
            await buildSubmodules(contracts);
            process.exit(0);
            break;
        case '--diff':
            console.log(await getDiffBetweenLatestTags());
            process.exit(0);
        default:
            await deploy();
            process.exit(0);
    }
}

main().catch((e) => {
    console.log(e);
    process.exit(1);
});
