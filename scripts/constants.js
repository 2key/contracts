const simpleGit = require('simple-git/promise');

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
    'develop-public' : 'https://rpc-staging.public.test.k8s.2key.net',
    'develop-private' : 'https://rpc-staging.private.test.k8s.2key.net',
    'staging-public' : 'https://rpc-staging.public.test.k8s.2key.net',
    'staging-private' : 'https://rpc-staging.private.test.k8s.2key.net',
    'master-public' : 'https://rpc.public.prod.k8s.2key.net',
    'master-private' : 'https://rpc.private.production.k8s.2key.net',
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
        "TOKEN_SELL" :  [],
        "DONATION" : [],
    },
    "private": ["CPC_PLASMA", "CPC_NO_REWARDS_PLASMA"]
};

module.exports.promisify = function (func, args) {
    return new Promise((res, rej) => {
        func(...args, (err, data) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}


