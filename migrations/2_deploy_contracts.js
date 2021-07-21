const Oracle = artifacts.require("../contracts/Oracle.sol");
const XTRXToken = artifacts.require("../contracts/XTRXToken.sol");
const PoolController = artifacts.require("../contracts/PoolController.sol");
const Poker = artifacts.require("../contracts/Poker.sol");
// const FakePoker = artifacts.require("../contracts/testContracts/FakePoker.sol");

module.exports = function(deployer, network, owner) {
  deployer.then(async () => {
    const xTRX = await deployer.deploy(XTRXToken);
    const oracle = await deployer.deploy(Oracle, owner);
    const poolController = await deployer.deploy(PoolController, xTRX.address);
    await deployer.deploy(Poker, oracle.address, poolController.address, owner);
    // await deployer.deploy(FakePoker, oracle.address, poolController.address);
  });
};
