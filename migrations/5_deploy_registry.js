const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const Call = artifacts.require('Call');

module.exports = function deploy(deployer) {
    deployer.deploy(Call)
        .then(() => Call.deployed())
        .then(() => deployer.link(Call, TwoKeyRegistry))
        .then(() => deployer.deploy(TwoKeyRegistry))
        .then(() => true);
}