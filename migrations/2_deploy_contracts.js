const Contract = artifacts.require("./passwordEscrow.sol");

module.exports = function(deployer) {
  const fee = 0;
  deployer.deploy(Contract, fee);
};
