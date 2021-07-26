const simpleGit = require('simple-git/promise');
const config = require('../configurationFiles/accountsConfig.json');

module.exports.getGitBranch = () => new Promise(async(resolve,reject) => {
    try {
        const currentRepo = simpleGit();
        let branchStatus = await currentRepo.status();
        resolve(branchStatus.current);
    } catch (e) {
        reject(e);
    }
});


module.exports.rpcs = {
    'develop-public' : config["test-public"],
    'develop-private' : config["test-private"],
    'staging-public' : config["staging-public"],
    'staging-private' : config["staging-private"],
    'master-public' : config["prod-public"],
    'master-private' : config["prod-private"],
};

module.exports.ids = {
    'develop-public' : 3,
    'develop-private' : 182,
    'staging-public' : 3,
    'staging-private' : 182,
    'master-public' : 1,
    'master-private' : 180,
};

module.exports.campaigns = {
    "public": {
        "TOKEN_SELL" : ["TwoKeyAcquisitionCampaignERC20","TwoKeyAcquisitionLogicHandler","TwoKeyConversionHandler","TwoKeyPurchasesHandler"],
        "DONATION" : ["TwoKeyDonationCampaign", "TwoKeyDonationConversionHandler","TwoKeyDonationLogicHandler"]
    },
    "private": {
        "CPC_PLASMA" :  ["TwoKeyCPCCampaignPlasma"],
        "CPC_NO_REWARDS_PLASMA" : ["TwoKeyCPCCampaignPlasmaNoReward"]
    }
};

module.exports.promisify = function (func, args) {
    return new Promise((res, rej) => {
        func(...args, (err, data) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}


