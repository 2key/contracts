var TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
module.exports = function(deployer) {
  deployer.deploy(TwoKeyAdmin);
};
