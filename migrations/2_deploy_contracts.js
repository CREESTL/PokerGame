const Oracle = artifacts.require("../contracts/Oracle.sol");
const XETHToken = artifacts.require("../contracts/XETHToken.sol");
const PoolController = artifacts.require("../contracts/PoolController.sol");
const Poker = artifacts.require("../contracts/Poker.sol");

module.exports = function(deployer, network, owner) {
  deployer.then(async () => {
    const xETH = await deployer.deploy(XETHToken);
    const oracle = await deployer.deploy(Oracle, owner);
    const poolController = await deployer.deploy(PoolController, xETH.address);
    await deployer.deploy(Poker, oracle.address, poolController.address);
  });
};
